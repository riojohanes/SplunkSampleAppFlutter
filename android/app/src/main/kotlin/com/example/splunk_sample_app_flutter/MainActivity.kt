package com.example.splunk_sample_app_flutter

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val NATIVE_CRASH_CHANNEL = "splunk_sample/native_crash"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CRASH_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "crash") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                result.success(null)
                // Deferred so the throw escapes this call's try/catch and the
                // method channel's own dispatch, producing a real crash
                // instead of an error reply back to Dart.
                Handler(Looper.getMainLooper()).post {
                    throw RuntimeException(
                        "Deliberate native crash for crash reporting verification."
                    )
                }
            }
    }
}
