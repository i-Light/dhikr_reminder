package com.gratovo.dhikr_reminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

/**
 * The reminder as an ordinary notification: what arrives when the card cannot
 * be drawn (the permission was withdrawn, or the system refused to start the
 * service or the lock-screen card from the background). A reminder is never
 * dropped silently.
 */
object ReminderNotifier {
    private const val CHANNEL_ID = "dhikr_reminders"
    private const val NOTIFICATION_BASE = 20_000

    fun post(context: Context, reminder: ReminderStore.Planned) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        // The same channel the Dart side's notifications use.
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Dhikr reminders", NotificationManager.IMPORTANCE_HIGH),
        )
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(ReminderStore.title(context))
            .setContentText(reminder.text)
            .setStyle(Notification.BigTextStyle().bigText(reminder.text))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        manager.notify(NOTIFICATION_BASE + reminder.id, notification)
    }
}
