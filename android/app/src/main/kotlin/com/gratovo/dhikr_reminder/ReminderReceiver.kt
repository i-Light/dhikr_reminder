package com.gratovo.dhikr_reminder

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
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
        if (OverlayService.busy || LockScreenReminderActivity.isShowing) {
            ReminderStore.log(context, "skipped", "a card is still up")
            return
        }

        // A pause set in the app holds back anything still armed inside it.
        if (PendingRules.isPaused(
                System.currentTimeMillis(),
                ReminderStore.pausedUntilMillis(context),
            )
        ) {
            ReminderStore.log(context, "skipped", "paused")
            return
        }

        if (!Settings.canDrawOverlays(context)) {
            ReminderNotifier.post(context, reminder)
            ReminderStore.markDelivered(context)
            ReminderStore.log(context, "notification", "no overlay permission")
            return
        }

        if (Features.POLITE_REMINDERS) {
            // Quiet hours set in the app: nothing is shown, nothing is saved up.
            val quietNow = QuietWindow.containsMillis(
                System.currentTimeMillis(),
                ReminderStore.quietStart(context),
                ReminderStore.quietEnd(context),
            )
            if (quietNow) {
                ReminderStore.log(context, "skipped", "quiet hours")
                return
            }
            // During Do Not Disturb or a call the floating card would be an
            // intrusion; the same dhikr waits in the notifications instead.
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (!PendingRules.cardIsWelcome(manager.currentInterruptionFilter, audio.mode)) {
                ReminderNotifier.post(context, reminder)
                ReminderStore.markDelivered(context)
                ReminderStore.log(context, "notification", "do not disturb or a call")
                return
            }
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
                ReminderStore.markDelivered(context)
                ReminderStore.log(context, "lockscreen")
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
                ReminderStore.markDelivered(context)
                ReminderStore.log(context, "card")
            }
        } catch (e: Exception) {
            // Android 12+ can refuse a foreground service started from the
            // background; fall back to the notification. What the system said
            // goes in the log, so a bug report shows why the card did not come.
            ReminderStore.clearPending(context)
            ReminderNotifier.post(context, reminder)
            ReminderStore.markDelivered(context)
            ReminderStore.log(context, "notification", e.javaClass.simpleName)
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
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            // The clock or the time zone changed: the armed alarms were set
            // against the old one, so arm them again.
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                ReminderStore.log(context, "rearmed", intent.action?.substringAfterLast('.') ?: "")
                ReminderAlarms.topUp(context)
                HealthJob.ensureScheduled(context)
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
