package com.example.notilog

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "notilog/native"
    private val eventChannelName = "notilog/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(NotificationEventStream)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationAccessSettings" -> {
                        openNotificationAccessSettings()
                        result.success(null)
                    }
                    "isNotificationAccessEnabled" -> {
                        result.success(isNotificationAccessEnabled())
                    }
                    "drainNotificationBuffer" -> {
                        result.success(drainNotificationBuffer())
                    }
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val success = launchApp(packageName)
                            if (success) {
                                result.success(true)
                            } else {
                                result.error("LAUNCH_FAILED", "Could not find launch intent for $packageName", null)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "Package name is null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun isNotificationAccessEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return enabled.contains(packageName)
    }

    private fun drainNotificationBuffer(): List<Map<String, Any?>> {
        return NativeNotificationBuffer.drainRecent(applicationContext)
    }

    private fun launchApp(packageName: String): Boolean {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
            return true
        }
        return false
    }
}
