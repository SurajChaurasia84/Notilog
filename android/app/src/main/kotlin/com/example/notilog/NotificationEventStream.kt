package com.example.notilog

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object NotificationEventStream : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun postNotification(payload: Map<String, Any?>) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(payload)
        }
    }
}
