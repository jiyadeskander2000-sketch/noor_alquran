package com.quran.app.noor_alquran

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object AdhanAlarmScheduler {
    private const val preferencesName = "noor_background_adhan"
    private const val alarmsKey = "alarms"
    private const val filePathKey = "file_path"
    private const val actionPlayAdhan = "com.quran.app.noor_alquran.PLAY_ADHAN"
    private const val firstRequestCode = 4100
    private const val alarmCount = 70

    fun schedule(context: Context, filePath: String?, alarms: List<Map<String, Any>>) {
        cancelPendingAlarms(context)
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val jsonAlarms = JSONArray()
        alarms.forEach { alarm ->
            jsonAlarms.put(
                JSONObject()
                    .put("id", (alarm["id"] as Number).toInt())
                    .put("timestamp", (alarm["timestamp"] as Number).toLong())
                    .put("prayer", alarm["prayer"] as String)
            )
        }
        val editor = preferences.edit().putString(alarmsKey, jsonAlarms.toString())
        if (!filePath.isNullOrBlank()) {
            editor.putString(filePathKey, filePath)
        } else {
            editor.remove(filePathKey)
        }
        editor.apply()

        alarms.forEach { scheduleOne(context, filePath, it) }
    }

    fun restore(context: Context) {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val filePath = preferences.getString(filePathKey, null)
        val storedAlarms = preferences.getString(alarmsKey, null) ?: return
        val now = System.currentTimeMillis()
        val alarms = mutableListOf<Map<String, Any>>()
        val jsonAlarms = JSONArray(storedAlarms)
        for (index in 0 until jsonAlarms.length()) {
            val alarm = jsonAlarms.getJSONObject(index)
            if (alarm.getLong("timestamp") > now) {
                alarms.add(
                    mapOf(
                        "id" to alarm.getInt("id"),
                        "timestamp" to alarm.getLong("timestamp"),
                        "prayer" to alarm.getString("prayer")
                    )
                )
            }
        }
        if (alarms.isNotEmpty()) {
            schedule(context, filePath, alarms)
        }
    }

    fun cancel(context: Context) {
        cancelPendingAlarms(context)
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .remove(filePathKey)
            .remove(alarmsKey)
            .apply()
    }

    private fun cancelPendingAlarms(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        repeat(alarmCount) { index ->
            val pendingIntent = pendingIntent(context, firstRequestCode + index, null, null)
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    private fun scheduleOne(context: Context, filePath: String?, alarm: Map<String, Any>) {
        val timestamp = (alarm["timestamp"] as Number).toLong()
        if (timestamp <= System.currentTimeMillis()) return

        val requestCode = firstRequestCode + (alarm["id"] as Number).toInt()
        val pendingIntent = pendingIntent(
            context,
            requestCode,
            filePath,
            alarm["prayer"] as String
        )

        val alarmManager = context.getSystemService(AlarmManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
        }
    }

    private fun pendingIntent(
        context: Context,
        requestCode: Int,
        filePath: String?,
        prayer: String?
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).setAction(actionPlayAdhan)
        if (filePath != null) intent.putExtra(AdhanPlaybackService.extraFilePath, filePath)
        if (prayer != null) intent.putExtra(AdhanPlaybackService.extraPrayerName, prayer)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
