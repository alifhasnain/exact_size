package com.exactsize.exact_size

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentResolver
import android.content.ComponentName
import android.content.ContentValues
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.file.FileAlreadyExistsException
import java.nio.file.Files
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * FEAT-007 export bridge (ADR-007, tech.md section 4.1) on `exactsize/export`. Only strings, ints,
 * bools and enum names cross the channel. Exception text is never read; errors are
 * `internalError` with no message (FR-27). Nothing here logs. Blocking work runs on one
 * background thread; results are posted on the main thread.
 */
class ExportBridge(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "exactsize/export"
        const val REQUEST_SAVE_AS = 4104
        const val REQUEST_WRITE = 4105
        private const val SCAN_WAIT_MS = 2000L
        private const val CHUNK = 64 * 1024
        private const val FOLDER = "ExactSize"
        private const val SPACE_MARGIN = 1024L * 1024

        /** Every MediaStore collection query here is limited to our own items in our own folder (FR-8, FR-16). */
        private val SWEEP_SELECTION = "${MediaStore.MediaColumns.RELATIVE_PATH} = ? AND ${MediaStore.MediaColumns.OWNER_PACKAGE_NAME} = ? AND " +
            "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE 'exactsize-%'"
        private val PART = Regex("""^\.exactsize-.+\.(jpg|png)\.part$""")
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val io: ExecutorService = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** API 28: the save call waiting for the permission dialog; lost with the activity (FR-25). */
    private var waitingForWrite: (() -> Unit)? = null
    private var deniedWrite: (() -> Unit)? = null

    /** The save-as call waiting for the system dialog; lost with the activity (FR-25, risk R8). */
    private var waitingForDocument: ((Uri?) -> Unit)? = null

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                handle(call, result)
            } catch (_: Throwable) {
                result.error("internalError", null, null)
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    /** Forwarded by MainActivity; true when the request code was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SAVE_AS) return false
        val doc = if (resultCode == Activity.RESULT_OK) data?.data else null
        val next = waitingForDocument
        waitingForDocument = null
        if (next != null) {
            next(doc)
        } else if (doc != null) {
            // R8: a result with no waiting call (the activity was recreated): remove the empty document.
            io.execute { deleteDocument(doc) }
        }
        return true
    }

    /** Forwarded by MainActivity; true when the request code was ours. */
    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_WRITE) return false
        val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        val next = if (granted) waitingForWrite else deniedWrite
        waitingForWrite = null
        deniedWrite = null
        next?.invoke()
        return true
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "save" -> {
                val src = call.argument<String>("src"); val name = call.argument<String>("name")
                val mime = call.argument<String>("mime"); val bytes = call.argument<Number>("bytes")?.toLong()
                if (src == null || name == null || mime == null || bytes == null) return result.success(mapOf("outcome" to "failed"))
                if (Build.VERSION.SDK_INT >= 29) background(result) { saveMediaStore(src, name, mime, bytes) }
                else saveLegacy(src, name, mime, bytes, result)
            }
            "saveAs" -> {
                val src = call.argument<String>("src"); val name = call.argument<String>("name")
                val mime = call.argument<String>("mime"); val bytes = call.argument<Number>("bytes")?.toLong()
                if (src == null || name == null || mime == null || bytes == null) return result.success(mapOf("outcome" to "failed"))
                saveAs(src, name, mime, bytes, result)
            }
            "sweepIncomplete" -> background(result) { sweepIncomplete(); null }
            // Device tests only (debuggable builds): plant or count unfinished saves (FEAT-007-T09).
            "debugPlantIncomplete" -> if (debuggable()) background(result) { plantIncomplete(); null } else result.notImplemented()
            "debugCountIncomplete" -> if (debuggable()) background(result) { incomplete().size } else result.notImplemented()
            "debugShareDisplayName" -> if (debuggable()) background(result) { shareDisplayName(call.argument<String>("path")!!) } else result.notImplemented()
            "itemExists" -> background(result) { itemExists(call.argument<String>("ref")) }
            "open" -> open(call.argument<String>("ref"), call.argument<String>("mime"), result)
            "share" -> result.success(share(call.argument<String>("path"), call.argument<String>("mime")))
            else -> result.notImplemented()
        }
    }

    /** Runs [work] off the main thread; posts its value, or internalError, back on the main thread. */
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            val out = try {
                Result.success(work())
            } catch (_: Throwable) {
                Result.failure(Exception())
            }
            main.post { out.fold({ result.success(it) }, { result.error("internalError", null, null) }) }
        }
    }

    /**
     * FR-6, API 29+: pending MediaStore row in Pictures/ExactSize, chunked copy, size check, publish.
     * The row is deleted on any failure, so no partial item is ever visible (FR-3, NFR-6). MediaStore
     * renames a taken name itself (T01 spike), so nameTaken is never returned here; the stored name
     * is read back (FR-11, FR-13). Blocking: runs on the background thread.
     */
    private fun saveMediaStore(src: String, name: String, mime: String, bytes: Long): Map<String, String> {
        val source = File(src)
        if (!source.isFile || source.length() != bytes) return mapOf("outcome" to "fileMissing")
        val resolver = activity.contentResolver
        val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = try {
            resolver.insert(collection, ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$FOLDER")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            })
        } catch (_: Throwable) {
            null
        } ?: return failure(bytes)
        try {
            resolver.openFileDescriptor(uri, "w")!!.use { pfd ->
                FileOutputStream(pfd.fileDescriptor).use { out ->
                    FileInputStream(source).use { input -> copy(input, out) }
                    out.flush()
                    out.fd.sync()
                }
            }
            val written = resolver.openFileDescriptor(uri, "r")!!.use { it.statSize }
            if (written != bytes) {
                delete(uri)
                return mapOf("outcome" to "failed")
            }
            resolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
            val stored = resolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)
                ?.use { if (it.moveToFirst()) it.getString(0) else null } ?: name
            return mapOf("outcome" to "saved", "name" to stored, "ref" to uri.toString())
        } catch (_: Throwable) {
            delete(uri)
            return failure(bytes)
        }
    }

    /**
     * FR-7, API 28: the permission is checked and, if missing, asked for inside this call, once per
     * call; no "asked before" flag is kept. After "don't ask again" the platform denies at once
     * (AC-2.4). Never asks for the read permission: the dialog grants the storage group.
     */
    private fun saveLegacy(src: String, name: String, mime: String, bytes: Long, result: MethodChannel.Result) {
        val go = { background(result) { writeLegacy(src, name, mime, bytes) } }
        if (activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) return go()
        if (waitingForWrite != null) return result.success(mapOf("outcome" to "failed")) // a request is already showing
        waitingForWrite = go
        deniedWrite = { result.success(mapOf("outcome" to "permissionDenied")) }
        activity.requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), REQUEST_WRITE)
    }

    /**
     * API 28 write: `.part` file (leading dot, non-media extension) in Pictures/ExactSize, size check,
     * rename without replace (an existing file is never overwritten, FR-13), media scan of the final
     * file only (a scan aimed at the `.part` would index it; T01 spike). Touches only this folder (FR-8).
     */
    @Suppress("DEPRECATION")
    private fun writeLegacy(src: String, name: String, mime: String, bytes: Long): Map<String, String> {
        val source = File(src)
        if (!source.isFile || source.length() != bytes) return mapOf("outcome" to "fileMissing")
        val dir = exactSizeDir()
        val target = File(dir, name)
        val part = File(dir, ".$name.part")
        try {
            if (!dir.isDirectory && !dir.mkdirs()) return failure(bytes)
            if (target.exists() || part.exists()) return mapOf("outcome" to "nameTaken")
            FileOutputStream(part).use { out ->
                FileInputStream(source).use { input -> copy(input, out) }
                out.flush()
                out.fd.sync()
            }
            if (part.length() != bytes) {
                part.delete()
                return mapOf("outcome" to "failed")
            }
            try {
                Files.move(part.toPath(), target.toPath())
            } catch (_: FileAlreadyExistsException) {
                part.delete()
                return mapOf("outcome" to "nameTaken")
            }
        } catch (_: Throwable) {
            part.delete()
            return failure(bytes)
        }
        val uri = try { scan(target.path, mime) } catch (_: Throwable) { null }
        return mapOf("outcome" to "saved", "name" to name, "ref" to (uri?.toString() ?: target.path))
    }

    /**
     * FR-10 (Should): the system save-as dialog with the FR-4 name; no permission on any version.
     * The copy is checked by size; on failure the created document is deleted (best effort).
     * Closing the dialog answers cancelled, which shows no message.
     */
    private fun saveAs(src: String, name: String, mime: String, bytes: Long, result: MethodChannel.Result) {
        val source = File(src)
        if (!source.isFile || source.length() != bytes) return result.success(mapOf("outcome" to "fileMissing"))
        if (waitingForDocument != null) return result.success(mapOf("outcome" to "failed"))
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType(mime).putExtra(Intent.EXTRA_TITLE, name)
        waitingForDocument = { doc ->
            if (doc == null) result.success(mapOf("outcome" to "cancelled"))
            else background(result) { writeDocument(source, doc, bytes) }
        }
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, REQUEST_SAVE_AS)
        } catch (_: Throwable) {
            waitingForDocument = null
            result.success(mapOf("outcome" to "failed"))
        }
    }

    private fun writeDocument(source: File, doc: Uri, bytes: Long): Map<String, String> {
        val resolver = activity.contentResolver
        return try {
            resolver.openFileDescriptor(doc, "w")!!.use { pfd ->
                FileOutputStream(pfd.fileDescriptor).use { out ->
                    FileInputStream(source).use { input -> copy(input, out) }
                    out.flush()
                    out.fd.sync()
                }
            }
            val written = resolver.openFileDescriptor(doc, "r")!!.use { it.statSize }
            if (written != bytes) {
                deleteDocument(doc)
                return mapOf("outcome" to "failed")
            }
            val shown = resolver.query(doc, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { if (it.moveToFirst()) it.getString(0) else null } ?: ""
            mapOf("outcome" to "saved", "name" to shown, "ref" to doc.toString())
        } catch (_: Throwable) {
            deleteDocument(doc)
            failure(bytes)
        }
    }

    private fun deleteDocument(doc: Uri) {
        try {
            DocumentsContract.deleteDocument(activity.contentResolver, doc)
        } catch (_: Throwable) {
            // best effort
        }
    }

    @Suppress("DEPRECATION")
    private fun exactSizeDir() = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), FOLDER)

    /**
     * FR-16: removes this app's unfinished saves left by a kill: pending MediaStore rows (API 29+) or
     * `.part` files (API 28, only when WRITE is already granted; never asks). Completed files are never
     * touched. Runs on the save thread, so a Save tapped at launch waits for it. Logs nothing.
     */
    private fun sweepIncomplete() {
        val resolver = activity.contentResolver
        val args = arrayOf("${Environment.DIRECTORY_PICTURES}/$FOLDER/", activity.packageName)
        when {
            Build.VERSION.SDK_INT >= 30 -> {
                val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val query = Bundle().apply {
                    putString(ContentResolver.QUERY_ARG_SQL_SELECTION, SWEEP_SELECTION)
                    putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, args)
                    putInt(MediaStore.QUERY_ARG_MATCH_PENDING, MediaStore.MATCH_ONLY)
                }
                deleteRows(collection, resolver.query(collection, arrayOf(MediaStore.MediaColumns._ID), query, null))
            }
            Build.VERSION.SDK_INT == 29 -> {
                @Suppress("DEPRECATION")
                val collection = MediaStore.setIncludePending(MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY))
                deleteRows(collection, resolver.query(collection, arrayOf(MediaStore.MediaColumns._ID),
                    "$SWEEP_SELECTION AND ${MediaStore.MediaColumns.IS_PENDING} = 1", args, null))
            }
            activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED ->
                exactSizeDir().listFiles()?.filter { it.isFile && PART.matches(it.name) }?.forEach { it.delete() }
        }
    }

    private fun deleteRows(collection: Uri, cursor: android.database.Cursor?) {
        for (uri in ids(collection, cursor)) delete(uri)
    }

    private fun ids(collection: Uri, cursor: android.database.Cursor?): List<Uri> {
        val ids = mutableListOf<Uri>()
        cursor?.use { while (it.moveToNext()) ids += android.content.ContentUris.withAppendedId(collection, it.getLong(0)) }
        return ids
    }

    private fun debuggable() = (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    /** Debug only: what the sweep would remove (API 30+ pending rows, API 28 `.part` files). */
    private fun incomplete(): List<Any> {
        if (Build.VERSION.SDK_INT >= 30) {
            val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val query = Bundle().apply {
                putString(ContentResolver.QUERY_ARG_SQL_SELECTION, SWEEP_SELECTION)
                putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, arrayOf("${Environment.DIRECTORY_PICTURES}/$FOLDER/", activity.packageName))
                putInt(MediaStore.QUERY_ARG_MATCH_PENDING, MediaStore.MATCH_ONLY)
            }
            return ids(collection, activity.contentResolver.query(collection, arrayOf(MediaStore.MediaColumns._ID), query, null))
        }
        return exactSizeDir().listFiles()?.filter { it.isFile && PART.matches(it.name) } ?: emptyList()
    }

    /** Debug only: the display name a receiving app reads for a share copy (FR-5, H5). */
    private fun shareDisplayName(path: String): String? {
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.share", File(path))
        return activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { if (it.moveToFirst()) it.getString(0) else null }
    }

    /** Debug only: an unfinished save as a kill would leave it, with synthetic bytes. */
    private fun plantIncomplete() {
        val stamp = System.nanoTime().toString(36).takeLast(6).padStart(6, '0')
        if (Build.VERSION.SDK_INT >= 29) {
            val uri = activity.contentResolver.insert(MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY), ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, "exactsize-1x1-$stamp.jpg")
                put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$FOLDER")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }) ?: return
            activity.contentResolver.openOutputStream(uri, "w")?.use { it.write(ByteArray(1024) { i -> i.toByte() }) }
        } else {
            exactSizeDir().apply { mkdirs() }.let { File(it, ".exactsize-1x1-$stamp.jpg.part").writeBytes(ByteArray(1024) { i -> i.toByte() }) }
        }
    }

    private fun copy(input: FileInputStream, out: FileOutputStream) {
        val buf = ByteArray(CHUNK)
        while (true) {
            val n = input.read(buf)
            if (n < 0) break
            out.write(buf, 0, n)
        }
    }

    private fun delete(uri: Uri) {
        try {
            activity.contentResolver.delete(uri, null, null)
        } catch (_: Throwable) {
            // best effort; the start-up sweep removes a pending row left behind (FR-16)
        }
    }

    /** FR-14: noSpace when shared storage is nearly full, else failed. */
    private fun failure(bytes: Long): Map<String, String> {
        val free = try {
            StatFs(Environment.getExternalStorageDirectory().path).availableBytes
        } catch (_: Throwable) {
            Long.MAX_VALUE
        }
        return mapOf("outcome" to if (free < bytes + SPACE_MARGIN) "noSpace" else "failed")
    }

    /**
     * FR-12: the saved bytes are still there. A content URI is opened for reading (a stale MediaStore row
     * after a file-manager delete on API 28 does not count); an API 28 path is checked on disk. False on any error.
     */
    private fun itemExists(ref: String?): Boolean {
        if (ref.isNullOrEmpty()) return false
        return try {
            if (ref.startsWith("/")) {
                File(ref).isFile
            } else {
                activity.contentResolver.openFileDescriptor(Uri.parse(ref), "r")?.use { true } ?: false
            }
        } catch (_: Throwable) {
            false
        }
    }

    /** FR-15: a viewer with a read grant; an API 28 path whose scan timed out is scanned once more. */
    private fun open(ref: String?, mime: String?, result: MethodChannel.Result) {
        if (ref.isNullOrEmpty() || mime.isNullOrEmpty()) return result.success("noViewer")
        if (!ref.startsWith("/")) return result.success(view(Uri.parse(ref), mime))
        io.execute {
            val uri = try { scan(ref, mime) } catch (_: Throwable) { null }
            main.post { result.success(if (uri == null) "noViewer" else view(uri, mime)) }
        }
    }

    private fun view(uri: Uri, mime: String): String = try {
        activity.startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
        "opened"
    } catch (_: ActivityNotFoundException) {
        "noViewer"
    } catch (_: SecurityException) {
        "noViewer"
    }

    /** Media scan of [path]; the content URI, or null after [SCAN_WAIT_MS]. Blocking: call off the main thread. */
    private fun scan(path: String, mime: String): Uri? {
        var uri: Uri? = null
        val done = CountDownLatch(1)
        MediaScannerConnection.scanFile(activity, arrayOf(path), arrayOf(mime)) { _, u -> uri = u; done.countDown() }
        done.await(SCAN_WAIT_MS, TimeUnit.MILLISECONDS)
        return uri
    }

    /**
     * FR-17, FR-18, FR-20: one stream, read grant only, ExactSize excluded from the chooser.
     * getUriForFile throws for a file outside cache/exactsize_share/, which is the folder guard.
     */
    private fun share(path: String?, mime: String?): String = try {
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.share", File(path!!))
        val send = Intent(Intent.ACTION_SEND).setType(mime!!).putExtra(Intent.EXTRA_STREAM, uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        send.clipData = ClipData.newRawUri("", uri)
        val chooser = Intent.createChooser(send, null).putExtra(
            Intent.EXTRA_EXCLUDE_COMPONENTS,
            arrayOf(ComponentName(activity, ShareTargetActivity::class.java), ComponentName(activity, MainActivity::class.java)),
        )
        activity.startActivity(chooser)
        "opened"
    } catch (_: Throwable) {
        "failed"
    }
}
