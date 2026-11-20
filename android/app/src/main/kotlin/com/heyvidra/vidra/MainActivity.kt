package com.heyvidra.vidra

import android.app.Activity
import android.content.Intent
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Voice search, through the system's own recognizer UI.
 *
 * The system activity owns the microphone, so this app asks for no audio
 * permission and bundles no speech engine. The cost is that it only exists
 * where the device ships a recognizer (Google TV and friends): `available`
 * says whether it does, and the Dart side hides the button when it does not.
 */
class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null

    private fun recognizeIntent(language: String?) =
        Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            if (language != null) putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vidra/voice")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(
                        recognizeIntent(null).resolveActivity(packageManager) != null,
                    )
                    "listen" -> {
                        // A second request while one is up would strand the
                        // first caller's future forever.
                        pending?.success(null)
                        pending = result
                        try {
                            startActivityForResult(
                                recognizeIntent(call.argument<String>("language")),
                                REQUEST_SPEECH,
                            )
                        } catch (e: Exception) {
                            pending = null
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_SPEECH) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val text = if (resultCode == Activity.RESULT_OK) {
            data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
        } else {
            null
        }
        pending?.success(text)
        pending = null
    }

    private companion object {
        const val REQUEST_SPEECH = 7301
    }
}
