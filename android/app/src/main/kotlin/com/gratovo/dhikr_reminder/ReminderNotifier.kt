package com.gratovo.dhikr_reminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon

/**
 * The reminder as an ordinary notification: what arrives when the card cannot
 * be drawn (the permission was withdrawn, or the system refused to start the
 * service or the lock-screen card from the background). A reminder is never
 * dropped silently.
 */
object ReminderNotifier {
    private const val CHANNEL_ID = "dhikr_reminders"
    private const val NOTIFICATION_BASE = 20_000
    private const val DONE_CODE_BASE = 1_000_000
    private const val LATER_CODE_BASE = 2_000_000

    fun post(context: Context, reminder: ReminderStore.Planned) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Dhikr reminders", NotificationManager.IMPORTANCE_HIGH),
        )
        // One request code per reminder: extras do not tell two PendingIntents
        // apart, so a shared code would make every notification open the last
        // dhikr posted.
        val open = PendingIntent.getActivity(
            context,
            NOTIFICATION_BASE + reminder.id,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra(MainActivity.EXTRA_OPEN_DHIKR, reminder.dhikrId),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(ReminderStore.title(context))
            .setContentText(reminder.text)
            .setStyle(Notification.BigTextStyle().bigText(reminder.text))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setContentIntent(open)
            .setAutoCancel(true)
        if (Features.SURFACES) {
            // Say it, or put it off, without opening the app.
            val notificationId = NOTIFICATION_BASE + reminder.id
            builder.addAction(
                action(
                    context,
                    Surfaces.label(context, "done", R.string.action_done),
                    DONE_CODE_BASE + reminder.id,
                    reminder,
                    notificationId,
                    Surfaces.ACTION_DONE,
                ),
            )
            builder.addAction(
                action(
                    context,
                    Surfaces.label(context, "later", R.string.action_later),
                    LATER_CODE_BASE + reminder.id,
                    reminder,
                    notificationId,
                    Surfaces.ACTION_LATER,
                ),
            )
        }
        manager.notify(NOTIFICATION_BASE + reminder.id, builder.build())
    }

    /** A button that sends [reminder] to [SurfaceReceiver] as [what]. Broadcasts, since Android 12 forbids a notification starting an activity through a relay. */
    private fun action(
        context: Context,
        label: String,
        code: Int,
        reminder: ReminderStore.Planned,
        notificationId: Int,
        what: String,
    ): Notification.Action {
        val intent = Intent(context, SurfaceReceiver::class.java)
            .setAction(what)
            .putExtra(SurfaceReceiver.EXTRA_DHIKR, reminder.dhikrId)
            .putExtra(SurfaceReceiver.EXTRA_TEXT, reminder.text)
            .putExtra(SurfaceReceiver.EXTRA_AMOUNT, reminder.amount)
            .putExtra(SurfaceReceiver.EXTRA_GOAL, reminder.goal)
            .putExtra(SurfaceReceiver.EXTRA_TRANSLIT, reminder.translit)
            .putExtra(SurfaceReceiver.EXTRA_NOTIFICATION, notificationId)
        val pending = PendingIntent.getBroadcast(
            context,
            code,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Action.Builder(
            Icon.createWithResource(context, R.drawable.ic_notification),
            label,
            pending,
        ).build()
    }
}
