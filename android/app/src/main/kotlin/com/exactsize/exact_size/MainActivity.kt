package com.exactsize.exact_size

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.StatFs
import android.provider.MediaStore
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.security.SecureRandom

/**
 * FEAT-001 system picker bridge (ADR-006, tech.md section 4). Only enum names, booleans and the
 * provider's content URI cross the channel; exception text, file names from providers and result
 * extras never do (FR-19). Nothing here logs.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "exactsize/system_picker"
        const val REQUEST_GALLERY = 4101
        const val REQUEST_CAMERA = 4102
        const val REQUEST_FILES = 4103
        const val KEY_OUTSTANDING = "exactsize.pick.outstanding"
        const val KEY_PENDING_CAPTURE = "es.pendingCapture"
        const val KEY_SHARE_CONSUMED = "es.shareConsumed"

        /** Below this much free cache space the camera is not started (FR-5, OQ-T3). */
        const val MIN_FREE_BYTES = 32L * 1024 * 1024

        /** One pending result, cleared by takeResult (FR-15). Survives activity recreation. */
        var slot: Map<String, Any?>? = null
    }

    private var channel: MethodChannel? = null

    /** FEAT-007 export bridge (ADR-007), alive with the Flutter engine. */
    private var export: ExportBridge? = null
    private var launchOutstanding = false

    /** Random name of the camera file while the camera app is open (FR-11, FR-17 marker). */
    private var pendingCapture: String? = null

    /** The marker came back from the saved-state Bundle: this activity was recreated, possibly after process death (FR-17). */
    private var captureRestored = false

    /**
     * A launcher start on top of a running picker or camera (G1 finding g). It finishes at once, but its
     * Flutter engine still runs Dart main(); answering every call with an error keeps that Dart start from
     * sweeping a capture the camera is still writing (T20 finding).
     */
    private var duplicate = false

    /** A forwarded share was already put in the slot; recreation must not deliver it again (FR-20). */
    private var shareConsumed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        launchOutstanding = savedInstanceState?.getBoolean(KEY_OUTSTANDING) ?: false
        pendingCapture = savedInstanceState?.getString(KEY_PENDING_CAPTURE)
        captureRestored = pendingCapture != null
        shareConsumed = savedInstanceState?.getBoolean(KEY_SHARE_CONSUMED) ?: false
        // G1 finding (g): the launcher icon tapped while a picker or the camera runs in this task
        // would start a second MainActivity on top; finish it so the system UI stays in front.
        // Decided before super.onCreate, which configures the engine and its channel.
        duplicate = !isTaskRoot && intent?.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)
        super.onCreate(savedInstanceState)
        if (duplicate) finish() else if (!shareConsumed) takeShare(intent) // cold start; Dart's build takes the slot
    }

    /** Warm share (FR-20): ShareTargetActivity reached the running instance (singleTop). */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (!duplicate && takeShare(intent)) channel?.invokeMethod("resultReady", null)
    }

    /**
     * Puts a share forwarded by ShareTargetActivity in the slot. Ignored when the intent is replayed
     * from recents. Own-provider URIs are flagged so Dart refuses them (AC-8.2); a missing stream is
     * notOpenable. Returns whether the slot changed.
     */
    private fun takeShare(intent: Intent?): Boolean {
        if (intent?.action != ShareTargetActivity.ACTION) return false
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return false
        shareConsumed = true
        val uri = try {
            intent.getStringExtra(ShareTargetActivity.EXTRA_URI)?.let(Uri::parse)
        } catch (_: Throwable) {
            null
        }
        slot = if (uri == null) {
            mapOf("origin" to "share", "outcome" to "notOpenable")
        } else {
            mapOf("origin" to "share", "outcome" to "picked", "uri" to uri.toString(), "fromOwnApp" to isOwnProvider(uri))
        }
        return true
    }

    private fun isOwnProvider(uri: Uri): Boolean {
        val authority = uri.authority ?: return false
        return try {
            @Suppress("DEPRECATION")
            packageManager.resolveContentProvider(authority, 0)?.packageName == packageName
        } catch (_: Throwable) {
            false
        }
    }

    /**
     * FR-17, AC-5.2: onActivityResult runs before onResume on return (gate G1 item b), so a marker
     * still set here means the camera's result never arrived: report the capture as lost.
     */
    override fun onResume() {
        super.onResume()
        if (duplicate) return
        val name = pendingCapture ?: return
        pendingCapture = null
        captureRestored = false
        launchOutstanding = false
        slot = mapOf("origin" to "camera", "outcome" to "captureLost", "fileName" to name)
        channel?.invokeMethod("resultReady", null)
    }

    /**
     * FR-12, best effort: the session ends when the activity finishes, so no camera file outlives it.
     * Not for the duplicate launcher instance (a capture may be in progress). Process kills and
     * force-stops never get here; the start-up sweep covers them. Nothing is logged.
     */
    override fun onDestroy() {
        if (isFinishing && !duplicate) {
            try {
                File(cacheDir, "camera").listFiles()?.forEach { it.delete() }
            } catch (_: Throwable) {
                // best effort; the next start sweeps
            }
        }
        super.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putBoolean(KEY_OUTSTANDING, launchOutstanding)
        pendingCapture?.let { outState.putString(KEY_PENDING_CAPTURE, it) }
        outState.putBoolean(KEY_SHARE_CONSUMED, shareConsumed)
        super.onSaveInstanceState(outState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                try {
                    handle(call, result)
                } catch (_: Throwable) {
                    result.error("internalError", null, null)
                }
            }
        }
        // A duplicate launcher instance finishes at once; it must not sweep or save (FEAT-001 T20 finding).
        if (!duplicate) export = ExportBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        export?.dispose()
        export = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (duplicate) return result.error("duplicate", null, null)
        when (call.method) {
            "launch" -> result.success(launch(call.argument<String>("source")))
            "cameraAvailable" -> result.success(Intent(MediaStore.ACTION_IMAGE_CAPTURE).resolveActivity(packageManager) != null)
            // Also the file of a camera result not yet taken: after recreation onActivityResult clears the
            // marker before Dart main() asks, and the start-up sweep must not delete that capture (T20).
            "pendingCaptureName" -> result.success(pendingCapture ?: slot?.get("fileName") as? String)
            "takeResult" -> {
                val r = slot
                slot = null
                result.success(r)
            }
            else -> result.notImplemented()
        }
    }

    /** Returns a LaunchOutcome name (FR-2, FR-3, AC-5.4). */
    private fun launch(source: String?): String {
        if (launchOutstanding) return "busy"
        return when (source) {
            "gallery" -> launchGallery()
            "camera" -> launchCamera()
            "files" -> launchFiles()
            else -> "unavailable"
        }
    }

    private fun launchGallery(): String {
        val openDocument = Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("image/*")
        val candidates = buildList {
            if (PickVisualMedia.isPhotoPickerAvailable(this@MainActivity)) {
                add(PickVisualMedia().createIntent(this@MainActivity, PickVisualMediaRequest(PickVisualMedia.ImageOnly)))
            }
            add(openDocument)
        }
        for (intent in candidates) {
            try {
                @Suppress("DEPRECATION")
                startActivityForResult(intent, REQUEST_GALLERY)
                launchOutstanding = true
                return "launched"
            } catch (_: ActivityNotFoundException) {
                // try the next one
            } catch (_: SecurityException) {
                // try the next one
            }
        }
        return "unavailable"
    }

    /** FR-21: the document picker, images only, one selection; no fallback. */
    private fun launchFiles(): String {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("image/*")
        return try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, REQUEST_FILES)
            launchOutstanding = true
            "launched"
        } catch (_: ActivityNotFoundException) {
            "unavailable"
        } catch (_: SecurityException) {
            "unavailable"
        }
    }

    private fun launchCamera(): String {
        if (StatFs(cacheDir.path).availableBytes < MIN_FREE_BYTES) return "lowSpace"
        val dir = File(cacheDir, "camera")
        val name = randomHex(16) + ".jpg"
        val file = File(dir, name)
        try {
            dir.mkdirs()
            if (!file.createNewFile()) return "lowSpace"
        } catch (_: IOException) {
            return "lowSpace"
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.camera", file)
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            .putExtra(MediaStore.EXTRA_OUTPUT, uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, REQUEST_CAMERA)
        } catch (_: ActivityNotFoundException) {
            file.delete()
            return "unavailable"
        }
        pendingCapture = name
        captureRestored = false
        launchOutstanding = true
        return "launched"
    }

    private fun randomHex(bytes: Int): String =
        ByteArray(bytes).also { SecureRandom().nextBytes(it) }.joinToString("") { "%02x".format(it) }

    @Deprecated("FlutterActivity has no ActivityResultRegistry; ADR-006 uses startActivityForResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (export?.onActivityResult(requestCode, resultCode, data) == true) return
        when (requestCode) {
            REQUEST_GALLERY -> galleryResult(resultCode, data, "gallery")
            REQUEST_FILES -> galleryResult(resultCode, data, "files")
            REQUEST_CAMERA -> cameraResult(resultCode)
            else -> return
        }
        channel?.invokeMethod("resultReady", null)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        export?.onRequestPermissionsResult(requestCode, grantResults)
    }

    private fun cameraResult(resultCode: Int) {
        launchOutstanding = false
        val name = pendingCapture
        val restored = captureRestored
        pendingCapture = null
        captureRestored = false
        // The camera's own result extras (thumbnail) are never read; the file is the result.
        val file = name?.let { File(File(cacheDir, "camera"), it) }
        slot = when {
            resultCode != RESULT_OK || file == null -> mapOf("origin" to "camera", "outcome" to "cancelled", "fileName" to name)
            // Recovery after recreation failed: the file is gone or empty (FR-17).
            restored && file.length() == 0L -> mapOf("origin" to "camera", "outcome" to "captureLost", "fileName" to name)
            else -> {
                val uri = FileProvider.getUriForFile(this, "$packageName.camera", file)
                mapOf("origin" to "camera", "outcome" to "captured", "uri" to uri.toString(), "fileName" to name)
            }
        }
    }

    private fun galleryResult(resultCode: Int, data: Intent?, origin: String) {
        launchOutstanding = false
        // Only the result URI is read; extras (including any file name) are ignored (FR-19).
        val uri = if (resultCode == RESULT_OK) data?.data else null
        slot = when {
            resultCode != RESULT_OK -> mapOf("origin" to origin, "outcome" to "cancelled")
            uri == null -> mapOf("origin" to origin, "outcome" to "notOpenable")
            else -> mapOf("origin" to origin, "outcome" to "picked", "uri" to uri.toString())
        }
    }
}
