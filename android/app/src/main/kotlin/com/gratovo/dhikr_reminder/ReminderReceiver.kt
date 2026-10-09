package com.gratovo.dhikr_reminder

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Settings

/**
 * An alarm went off: show that reminder.
 *
 * A reminder is never dropped silently. If the card cannot be drawn (the
 * permission was withdrawn, or the system refuses to start the service from
 * the background) the same dhikr arrives as an ordinary notification instead.
 * Either way the schedule is topped up afterwards, so it never runs dry.
 */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(ReminderAlarms.EXTRA_ID, -1)
        if (id < 0) return
        try {
            ReminderStore.find(context, id)?.let { ReminderDelivery.deliver(context, it) }
        } finally {
            ReminderAlarms.topUp(context)
        }
    }
}

/** How a reminder that is due gets to the person, whatever state the phone is in. */
object ReminderDelivery {
    fun deliver(context: Context, reminder: ReminderStore.Planned) {
        // Never interrupts a card that is still being counted, on the lock
        // screen or over an app.
        if (OverlayService.busy || LockScreenReminderActivity.isShowing) return

        if (!Settings.canDrawOverlays(context)) {
            ReminderNotifier.post(context, reminder)
            return
        }

        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val locked = PendingRules.isLocked(power.isInteractive, keyguard.isKeyguardLocked)

        try {
            if (locked) {
                // Lights the screen for 30 seconds, then waits for the next
                // unlock (see OverlayService). A newer reminder replaces an
                // older one nobody got to.
                ReminderStore.setPending(context, reminder, System.currentTimeMillis())
                context.startForegroundService(OverlayService.intentLocked(context))
            } else {
                // A fresh reminder in front of the person takes the place of
                // one that was still waiting.
                ReminderStore.clearPending(context)
                context.startForegroundService(
                    OverlayService.intentNow(
                        context,
                        reminder.dhikrId,
                        reminder.text,
                        reminder.amount,
                        reminder.goal,
                        reminder.translit,
                    ),
                )
            }
        } catch (e: Exception) {
            // Android 12+ can refuse a foreground service started from the
            // background; fall back to the notification.
            ReminderStore.clearPending(context)
            ReminderNotifier.post(context, reminder)
        }
    }
}

/**
 * The phone restarted, or this app was just updated: arm the stored plan again
 * (and extend it if it ran low), without waiting for the app to be opened, and
 * go back to waiting for the unlock if a reminder was still pending.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                ReminderAlarms.topUp(context)
                if (ReminderStore.pending(context, System.currentTimeMillis()) != null &&
                    Settings.canDrawOverlays(context)
                ) {
                    try {
                        context.startForegroundService(OverlayService.intentWatch(context))
                    } catch (e: Exception) {
                        // Not allowed to start it from here; the next reminder starts it.
                    }
                }
            }
        }
    }
}
