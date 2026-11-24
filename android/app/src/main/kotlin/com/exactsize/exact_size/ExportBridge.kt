package com.exactsize.exact_size

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ComponentName
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
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
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val io: ExecutorService = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

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
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean = requestCode == REQUEST_SAVE_AS

    /** Forwarded by MainActivity; true when the request code was ours. */
    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean = requestCode == REQUEST_WRITE

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "save", "saveAs" -> result.success(mapOf("outcome" to "failed")) // T06-T08
            "sweepIncomplete" -> result.success(null) // T09
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

    /** FR-12: a content URI (API 29+, save-as) is queried; an API 28 path is checked on disk. False on any error. */
    private fun itemExists(ref: String?): Boolean {
        if (ref.isNullOrEmpty()) return false
        return try {
            if (ref.startsWith("/")) {
                File(ref).isFile
            } else {
                activity.contentResolver.query(Uri.parse(ref), arrayOf(MediaStore.MediaColumns._ID), null, null, null)
                    ?.use { it.moveToFirst() } ?: false
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
