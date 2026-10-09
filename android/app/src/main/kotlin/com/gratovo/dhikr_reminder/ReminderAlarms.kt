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
 *
 * The plan Dart hands over covers about a day. So that reminders do not stop
 * when the app is not opened for longer than that, the plan keeps itself
 * topped up from here, natively (see [topUp] and [ReminderPlan]).
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
        HealthJob.ensureScheduled(context)
    }

    fun cancelAll(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (id in ReminderStore.armed(context)) {
            alarms.cancel(pending(context, id))
        }
        ReminderStore.saveArmed(context, emptyList())
    }

    /**
     * Makes sure the next day of reminders is armed, without Dart: after a
     * reboot, after the app is updated, and every time a reminder fires.
     * Extends the stored plan first if it ran low, then arms whatever it holds.
     */
    fun topUp(context: Context) {
        val plan = ReminderStore.plan(context)
        val extended = ReminderPlan.extend(
            plan,
            ReminderStore.intervalMillis(context),
            System.currentTimeMillis(),
            ReminderStore.pausedUntilMillis(context),
            ReminderStore.quietStart(context),
            ReminderStore.quietEnd(context),
        )
        if (extended !== plan) ReminderStore.replacePlan(context, extended)
        reschedule(context)
    }

    /** When the next reminder is due, in millis since the epoch, or 0 when none is armed. */
    fun nextDue(context: Context): Long =
        ReminderPlan.nextDue(
            ReminderStore.plan(context),
            System.currentTimeMillis(),
            ReminderStore.pausedUntilMillis(context),
        )

    /**
     * Throws away every alarm and the stored plan with it. The plan has to go
     * too: [topUp] runs after a reboot, an update and every fired reminder, and
     * would arm a plan that was only cancelled, not forgotten.
     */
    fun cancelAndForget(context: Context) {
        cancelAll(context)
        ReminderStore.clearPlan(context)
    }
}
