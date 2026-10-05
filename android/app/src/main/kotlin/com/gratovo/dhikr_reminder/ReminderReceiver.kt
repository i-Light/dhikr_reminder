package com.gratovo.dhikr_reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings

/** An alarm went off: show that reminder over whatever app is in front. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(ReminderAlarms.EXTRA_ID, -1)
        if (id < 0) return
        // Without the permission the overlay cannot be drawn; Dart schedules
        // ordinary notifications in that case, so there is nothing to do here.
        if (!Settings.canDrawOverlays(context)) return
        context.startForegroundService(OverlayService.intent(context, id))
    }
}

/** The phone restarted: alarms do not survive that, so arm the stored plan again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            ReminderAlarms.reschedule(context)
        }
    }
}
