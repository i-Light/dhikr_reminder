package com.gratovo.dhikr_reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

/**
 * Arms one alarm per planned reminder.
 *
 * Inexact on purpose (setAndAllowWhileIdle): a dhikr does not need to land on
 * the second, and exact alarms need a permission Google Play restricts. While
 * the phone dozes a reminder can arrive a few minutes late.
 */
object ReminderAlarms {
    const val EXTRA_ID = "reminder_id"

    private fun pending(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).putExtra(EXTRA_ID, id)
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /** Throws away the alarms set earlier and arms every future one in the stored plan. */
    fun reschedule(context: Context) {
        cancelAll(context)
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        val armed = ArrayList<Int>()
        for (reminder in ReminderStore.plan(context)) {
            if (reminder.atMillis <= now) continue
            alarms.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                reminder.atMillis,
                pending(context, reminder.id),
            )
            armed.add(reminder.id)
        }
        ReminderStore.saveArmed(context, armed)
    }

    fun cancelAll(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (id in ReminderStore.armed(context)) {
            alarms.cancel(pending(context, id))
        }
        ReminderStore.saveArmed(context, emptyList())
    }
}
