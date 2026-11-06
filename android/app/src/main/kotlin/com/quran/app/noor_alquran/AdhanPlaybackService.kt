package com.quran.app.noor_alquran

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.io.File

class AdhanPlaybackService : Service() {
    private var player: MediaPlayer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == actionStop) {
            stopPlayback()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        if (intent?.action == actionContinue) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            return START_NOT_STICKY
        }

        val filePath = intent?.getStringExtra(extraFilePath)
        val prayerName = intent?.getStringExtra(extraPrayerName) ?: "الصلاة"

        createNotificationChannel()

        val notification = createNotification(prayerName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(notificationId, notification)
        }

        stopPlayback()

        try {
            val rawResId = resources.getIdentifier("adhan", "raw", packageName)
            if (!filePath.isNullOrBlank() && File(filePath).exists()) {
                player = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    setDataSource(filePath)
                    setOnPreparedListener { it.start() }
                    setOnCompletionListener {
                        stopPlayback()
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        stopSelf()
                    }
                    setOnErrorListener { _, _, _ ->
                        stopPlayback()
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        stopSelf()
                        true
                    }
                    prepareAsync()
                }
            } else if (rawResId != 0) {
                player = MediaPlayer.create(this, rawResId)?.apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    setOnCompletionListener {
                        stopPlayback()
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        stopSelf()
                    }
                    setOnErrorListener { _, _, _ ->
                        stopPlayback()
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        stopSelf()
                        true
                    }
                    start()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopPlayback()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopPlayback()
        super.onDestroy()
    }

    private fun createNotification(prayerName: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        val stopIntent = PendingIntent.getService(
            this,
            notificationId,
            Intent(this, AdhanPlaybackService::class.java).setAction(actionStop),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val continueIntent = PendingIntent.getService(
            this,
            notificationId + 1,
            Intent(this, AdhanPlaybackService::class.java).setAction(actionContinue),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.noor_launcher_icon)
            .setContentTitle("🕌 حان الآن موعد أذان $prayerName")
            .setContentText("الله أكبر، الله أكبر • هل تريد إيقاف الأذان؟")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("🕌 حان الآن موعد أذان $prayerName")
                    .setSummaryText("نداء الصلاة")
                    .bigText("الله أكبر، الله أكبر • حيّ على الصلاة، حيّ على الفلاح\n\nهل ترغب في إيقاف صوت الأذان؟\n• اضغط «نعم (إيقاف)» لكتم الصوت فوراً\n• اضغط «لا (متابعة)» لمواصلة الاستماع للأذان")
            )
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(android.R.drawable.ic_media_pause, "نعم (إيقاف)", stopIntent)
            .addAction(android.R.drawable.ic_media_play, "لا (متابعة)", continueIntent)

        if (contentPendingIntent != null) {
            builder.setContentIntent(contentPendingIntent)
        }

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            channelId,
            "أذان الصلوات المفروضة",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات وأصوات الأذان مع خيارات الإيقاف أو المتابعة"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun stopPlayback() {
        player?.let { mediaPlayer ->
            player = null
            try {
                if (mediaPlayer.isPlaying) mediaPlayer.stop()
            } catch (_: IllegalStateException) {
            }
            mediaPlayer.release()
        }
    }

    companion object {
        const val extraFilePath = "custom_adhan_path"
        const val extraPrayerName = "prayer_name"
        private const val actionStop = "com.quran.app.noor_alquran.STOP_ADHAN"
        private const val actionContinue = "com.quran.app.noor_alquran.CONTINUE_ADHAN"
        private const val channelId = "background_adhan_playback"
        private const val notificationId = 4910
    }
}
