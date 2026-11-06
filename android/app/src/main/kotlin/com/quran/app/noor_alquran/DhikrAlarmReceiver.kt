package com.quran.app.noor_alquran

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class DhikrAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            val popupIntent = Intent(context, DhikrPopupActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            }
            context.startActivity(popupIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Reschedule next 5-minute reminder
        DhikrAlarmScheduler.scheduleNext(context)
    }
}
