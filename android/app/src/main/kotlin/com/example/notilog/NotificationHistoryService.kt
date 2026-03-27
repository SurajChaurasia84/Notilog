package com.example.notilog

import android.app.Notification
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Base64
import android.util.Log
import org.json.JSONObject
import java.io.ByteArrayOutputStream

class NotificationHistoryService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val payload = buildPayload(sbn) ?: return
        try {
            NativeNotificationBuffer.appendRecent(applicationContext, payload)
            NotificationEventStream.postNotification(payload.toMap())
        } catch (e: Exception) {
            Log.w("NotificationHistory", "Failed to store notification", e)
        }
    }

    private fun buildPayload(sbn: StatusBarNotification): JSONObject? {
        val notification = sbn.notification ?: return null
        val extras = notification.extras ?: return null

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val message = if (bigText.isNotEmpty()) bigText else text

        val packageName = sbn.packageName
        val appName = getAppName(packageName)
        val iconBytes = getAppIconBytes(packageName)
        val iconBase64 = iconBytes?.let { Base64.encodeToString(it, Base64.NO_WRAP) }

        val payload = JSONObject()
        payload.put("id", sbn.key)
        payload.put("appName", appName)
        payload.put("packageName", packageName)
        payload.put("title", title)
        payload.put("message", message)
        payload.put("timestamp", sbn.postTime)
        if (!iconBase64.isNullOrEmpty()) {
            payload.put("appIcon", iconBase64)
        }
        return payload
    }

    private fun getAppName(packageName: String): String {
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            drawableToBytes(drawable)
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBytes(drawable: Drawable): ByteArray? {
        val bitmap = when (drawable) {
            is BitmapDrawable -> drawable.bitmap
            else -> {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 64
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 64
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            }
        }
        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
        return output.toByteArray()
    }
}
