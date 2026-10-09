package com.gratovo.dhikr_reminder

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

/**
 * What the widget and the buttons on a reminder notification send: "count one",
 * "done" (the whole dhikr was said), "later" (bring it back in ten minutes)
 * and that return. A tap on any of them is the person using the app, which
 * Android treats as allowed to start work from the background.
 */
class SurfaceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!Features.SURFACES) return
        when (intent.action) {
            Surfaces.ACTION_COUNT -> Surfaces.countOne(context)

            Surfaces.ACTION_DONE -> {
                ReminderStore.addTaps(
                    context,
                    intent.getIntExtra(EXTRA_DHIKR, -1),
                    intent.getIntExtra(EXTRA_AMOUNT, 1),
                )
                dismiss(context, intent)
                Surfaces.refresh(context)
            }

            Surfaces.ACTION_LATER -> {
                dismiss(context, intent)
                snooze(context, intent)
            }

            Surfaces.ACTION_SNOOZED -> {
                if (!SurfaceRules.snoozeStillWanted(ReminderStore.intervalMillis(context))) return
                ReminderDelivery.deliver(
                    context,
                    ReminderStore.Planned(
                        id = SNOOZE_ID_BASE + intent.getIntExtra(EXTRA_DHIKR, 0),
                        atMillis = 0L,
                        dhikrId = intent.getIntExtra(EXTRA_DHIKR, 0),
                        text = intent.getStringExtra(EXTRA_TEXT) ?: "",
                        amount = intent.getIntExtra(EXTRA_AMOUNT, 1),
                        goal = intent.getIntExtra(EXTRA_GOAL, 0),
                        translit = intent.getStringExtra(EXTRA_TRANSLIT) ?: "",
                    ),
                )
            }
        }
    }

    private fun dismiss(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_NOTIFICATION, -1)
        if (id < 0) return
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id)
    }

    private fun snooze(context: Context, intent: Intent) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val dhikrId = intent.getIntExtra(EXTRA_DHIKR, 0)
        val again = Intent(context, SurfaceReceiver::class.java)
            .setAction(Surfaces.ACTION_SNOOZED)
            .putExtras(intent.extras ?: Bundle())
        alarms.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            SurfaceRules.snoozeAt(System.currentTimeMillis()),
            PendingIntent.getBroadcast(
                context,
                SNOOZE_CODE_BASE + dhikrId,
                again,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            ),
        )
        ReminderStore.log(context, "snoozed", "ten minutes")
    }

    companion object {
        const val EXTRA_DHIKR = "dhikr_id"
        const val EXTRA_TEXT = "text"
        const val EXTRA_AMOUNT = "amount"
        const val EXTRA_GOAL = "goal"
        const val EXTRA_TRANSLIT = "translit"
        const val EXTRA_NOTIFICATION = "notification_id"

        /** Ids and request codes that cannot meet the plan's own (which count up from 0). */
        const val SNOOZE_ID_BASE = 900_000
        const val SNOOZE_CODE_BASE = 60_000
    }
}

/**
 * A launcher shortcut's target for "Count one" and "Pause for 1 hour": does the
 * thing, says what happened in a toast and goes away without showing a screen.
 */
class ShortcutActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Features.SURFACES) {
            when (intent?.action) {
                Surfaces.ACTION_COUNT -> {
                    val total = Surfaces.countOne(this)
                    if (total == null) {
                        // Nothing to count yet: open the app instead.
                        startActivity(Intent(this, MainActivity::class.java))
                    } else {
                        say("${Surfaces.label(this, "today", R.string.widget_today)}: $total")
                    }
                }

                Surfaces.ACTION_PAUSE -> {
                    val until = Surfaces.togglePause(this)
                    say(
                        if (until > 0) {
                            Surfaces.pausedText(this, until)
                        } else {
                            Surfaces.label(this, "resume", R.string.tile_resume)
                        },
                    )
                }
            }
        }
        finish()
    }

    private fun say(text: String) = Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
}
