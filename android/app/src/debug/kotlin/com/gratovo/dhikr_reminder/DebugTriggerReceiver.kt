package com.gratovo.dhikr_reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Debug builds only. Delivers a reminder right now through exactly the path an
 * alarm takes (ReminderDelivery), so the lock-screen behaviour can be tried
 * from a computer without waiting for an alarm or changing the person's
 * schedule:
 *
 *     adb shell am broadcast -n com.gratovo.dhikr_reminder/.DebugTriggerReceiver \
 *         --ei goal 100 --es text "سبحان الله" --ei amount 3
 *
 * It lives in src/debug, so no release build contains it.
 */
class DebugTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val text = intent.getStringExtra("text") ?: "سبحان الله وبحمده"
        val amount = intent.getIntExtra("amount", 3)
        val goal = intent.getIntExtra("goal", 0)
        ReminderDelivery.deliver(context, ReminderStore.Planned(9000, 0L, 9000, text, amount, goal))
    }
}
