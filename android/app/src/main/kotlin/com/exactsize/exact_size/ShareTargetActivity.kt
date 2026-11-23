package com.exactsize.exact_size

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Parcelable

/**
 * FEAT-001 share target (FR-20, tech.md section 4, risk R6). No UI: it forwards the single shared
 * stream URI, with its read grant, to MainActivity in the app's own task and finishes, so no second
 * MainActivity and Flutter engine start in the sender's task. The intent's MIME type is never
 * trusted (the probe decides) and the stream is never opened here. Nothing here logs.
 */
class ShareTargetActivity : Activity() {
    companion object {
        const val ACTION = "com.exactsize.exact_size.SHARE"

        /** The shared URI as a string; never the intent data, which Flutter could read as a route. */
        const val EXTRA_URI = "es.shareUri"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            forward()
        } catch (_: Throwable) {
            // Nothing to show from a no-UI activity; the sender stays in front.
        }
        finish()
    }

    private fun forward() {
        val stream = try {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra<Parcelable>(Intent.EXTRA_STREAM) as? Uri
        } catch (_: Throwable) {
            null // malformed extras from an untrusted sender: treated as a missing stream
        }
        val out = Intent(this, MainActivity::class.java)
            .setAction(ACTION)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        stream?.let { out.putExtra(EXTRA_URI, it.toString()) }
        if (stream?.scheme == "content") {
            out.clipData = ClipData.newRawUri(null, stream)
            out.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivity(out)
        } catch (_: SecurityException) {
            // No grant to pass on (G1 finding 2): forward without it; the probe then reports
            // SOURCE_UNAVAILABLE ("couldn't open this photo", AC-8.5).
            out.clipData = null
            out.removeFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(out)
        }
    }
}
