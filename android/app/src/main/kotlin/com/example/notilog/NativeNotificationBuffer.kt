package com.example.notilog

import android.content.Context
import org.json.JSONObject
import java.io.File

object NativeNotificationBuffer {
    private const val fileName = "notification_buffer.jsonl"
    private const val retentionMillis = 24 * 60 * 60 * 1000L

    fun appendRecent(context: Context, payload: JSONObject) {
        try {
            val file = bufferFile(context)
            file.appendText(payload.toString() + "\n")
        } catch (_: Exception) {}
    }

    fun drainRecent(context: Context): List<Map<String, Any?>> {
        val cutoff = cutoffTimestamp()
        val file = bufferFile(context)
        if (!file.exists()) {
            return emptyList()
        }

        val items = mutableListOf<Map<String, Any?>>()
        file.bufferedReader().useLines { lines ->
            lines.forEach { line ->
                val json = parseRecent(line, cutoff) ?: return@forEach
                items.add(json.toMap())
            }
        }
        file.writeText("")
        return items
    }

    private fun parseRecent(line: String, cutoff: Long): JSONObject? {
        if (line.isBlank()) {
            return null
        }
        return try {
            val json = JSONObject(line)
            if (timestampOf(json) >= cutoff) json else null
        } catch (_: Exception) {
            null
        }
    }

    private fun timestampOf(json: JSONObject): Long {
        return when (val value = json.opt("timestamp")) {
            is Number -> value.toLong()
            is String -> value.toLongOrNull() ?: 0L
            else -> 0L
        }
    }

    private fun cutoffTimestamp(): Long {
        return System.currentTimeMillis() - retentionMillis
    }

    private fun bufferFile(context: Context): File {
        return File(context.filesDir, fileName)
    }

    private fun tempFile(context: Context): File {
        return File(context.filesDir, "$fileName.tmp")
    }
}

fun JSONObject.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val keys = keys()
    while (keys.hasNext()) {
        val key = keys.next()
        map[key] = get(key)
    }
    return map
}
