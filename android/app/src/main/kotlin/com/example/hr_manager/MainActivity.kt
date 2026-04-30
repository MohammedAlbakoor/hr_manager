package com.example.hr_manager

import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hr_manager/device_identifier",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceIdentifier" -> {
                    val androidId = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ANDROID_ID,
                    )

                    if (androidId.isNullOrBlank()) {
                        result.error(
                            "device_id_unavailable",
                            "Android device identifier is unavailable.",
                            null,
                        )
                    } else {
                        result.success(androidId)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
