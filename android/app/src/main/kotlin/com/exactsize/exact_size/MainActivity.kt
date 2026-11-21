package com.exactsize.exact_size

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * FEAT-001 system picker bridge (ADR-006, tech.md section 4). Only enum names, booleans and the
 * provider's content URI cross the channel; exception text, file names from providers and result
 * extras never do (FR-19). Nothing here logs.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "exactsize/system_picker"
        const val REQUEST_GALLERY = 4101
        const val KEY_OUTSTANDING = "exactsize.pick.outstanding"

        /** One pending result, cleared by takeResult (FR-15). Survives activity recreation. */
        var slot: Map<String, Any?>? = null
    }

    private var channel: MethodChannel? = null
    private var launchOutstanding = false

    override fun onCreate(savedInstanceState: Bundle?) {
        launchOutstanding = savedInstanceState?.getBoolean(KEY_OUTSTANDING) ?: false
        super.onCreate(savedInstanceState)
        // G1 finding (g): the launcher icon tapped while a picker or the camera runs in this task
        // would start a second MainActivity on top; finish it so the system UI stays in front.
        if (!isTaskRoot && intent?.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)) {
            finish()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putBoolean(KEY_OUTSTANDING, launchOutstanding)
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
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "launch" -> result.success(launch(call.argument<String>("source")))
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
            else -> "unavailable" // camera: T11; files: FR-21 task
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

    @Deprecated("FlutterActivity has no ActivityResultRegistry; ADR-006 uses startActivityForResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_GALLERY) return
        launchOutstanding = false
        // Only the result URI is read; extras (including any file name) are ignored (FR-19).
        val uri = if (resultCode == RESULT_OK) data?.data else null
        slot = when {
            resultCode != RESULT_OK -> mapOf("origin" to "gallery", "outcome" to "cancelled")
            uri == null -> mapOf("origin" to "gallery", "outcome" to "notOpenable")
            else -> mapOf("origin" to "gallery", "outcome" to "picked", "uri" to uri.toString())
        }
        channel?.invokeMethod("resultReady", null)
    }
}
