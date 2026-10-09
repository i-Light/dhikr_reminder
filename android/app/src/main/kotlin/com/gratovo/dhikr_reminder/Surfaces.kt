package com.gratovo.dhikr_reminder

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.service.quicksettings.TileService
import android.text.format.DateFormat
import java.util.Date

/**
 * The extra ways to count without opening the app: a home-screen widget, two
 * quick-settings tiles, launcher shortcuts and the buttons on a reminder
 * notification. They live outside the app, so the app's own screens stay as
 * they were.
 *
 * One switch ([Features.SURFACES]) turns all of it off: [apply] disables the
 * widget and the tiles and removes the shortcuts, and nothing here runs.
 *
 * Every one of them goes through [countOne] or [togglePause], which write to
 * the same store the reminder card does; the app collects the taps and the
 * pause the next time it is opened.
 */
object Surfaces {
    const val ACTION_COUNT = "com.gratovo.dhikr_reminder.COUNT"
    const val ACTION_PAUSE = "com.gratovo.dhikr_reminder.PAUSE"
    const val ACTION_DONE = "com.gratovo.dhikr_reminder.DONE"
    const val ACTION_LATER = "com.gratovo.dhikr_reminder.LATER"
    const val ACTION_SNOOZED = "com.gratovo.dhikr_reminder.SNOOZED"
    const val ACTION_LIBRARY = "com.gratovo.dhikr_reminder.LIBRARY"

    /** What the last refresh drew, so a refresh that would change nothing does nothing. */
    @Volatile
    private var lastDrawn = ""

    /** The text for [key] in the app's language, or the phone-language [fallback]. */
    fun label(context: Context, key: String, fallback: Int): String =
        ReminderStore.surfaceLabels(context)[key]?.takeIf { it.isNotBlank() }
            ?: context.getString(fallback)

    /**
     * Brings the widget, tiles and shortcuts in line with [Features.SURFACES].
     * With the switch on this does nothing (they are on in the manifest); with
     * it off it switches them off, once.
     */
    fun apply(context: Context) {
        val on = Features.SURFACES
        if (ReminderStore.surfacesState(context) == on) return
        val manager = context.packageManager
        val state = if (on) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        for (type in listOf(CountWidget::class.java, CountTile::class.java, PauseTile::class.java)) {
            manager.setComponentEnabledSetting(
                ComponentName(context, type),
                state,
                PackageManager.DONT_KILL_APP,
            )
        }
        if (!on) {
            try {
                context.getSystemService(ShortcutManager::class.java)?.removeAllDynamicShortcuts()
            } catch (e: Exception) {
                // Nothing to remove.
            }
        }
        ReminderStore.setSurfacesState(context, on)
    }

    /** One more tap on the dhikr the person was last reminded of; the new total, or null if none is known yet. */
    fun countOne(context: Context): Int? {
        val focus = ReminderStore.focus(context) ?: return null
        ReminderStore.addTap(context, focus.dhikrId)
        refresh(context)
        return ReminderStore.todayTotal(context)
    }

    /** Pauses the reminders for an hour, or lifts the pause if one is on. Returns the end of the pause, or 0. */
    fun togglePause(context: Context): Long {
        val until = SurfaceRules.pauseToggle(
            System.currentTimeMillis(),
            ReminderStore.pausedUntilMillis(context),
        )
        ReminderStore.setPausedFromSurface(context, until)
        ReminderStore.log(context, if (until > 0) "paused" else "resumed", "from a tile or shortcut")
        refresh(context)
        return until
    }

    /** "Paused until 14:30", in the app's language and the phone's time format. */
    fun pausedText(context: Context, untilMillis: Long): String {
        val time = DateFormat.getTimeFormat(context).format(Date(untilMillis))
        return label(context, "pausedUntil", R.string.paused_until).replace("{time}", time)
    }

    /** A reminder reached the person: that dhikr is the one the surfaces count now. */
    fun noteDelivered(context: Context, reminder: ReminderStore.Planned) {
        ReminderStore.setFocus(context, SurfaceRules.Focus(reminder.dhikrId, reminder.text))
        refresh(context)
    }

    /** The app handed over new words: show them. */
    fun onLabelsChanged(context: Context) {
        if (!Features.SURFACES) return
        publishShortcuts(context)
        refresh(context)
    }

    /** Redraws the widget and asks the tiles to redraw, if what they show has changed. */
    fun refresh(context: Context) {
        if (!Features.SURFACES) return
        val drawn = "${ReminderStore.todayTotal(context)}|${ReminderStore.focus(context)}|" +
            "${ReminderStore.pausedUntilMillis(context)}|${ReminderStore.surfaceLabels(context)}"
        if (drawn == lastDrawn) return
        lastDrawn = drawn
        try {
            CountWidget.updateAll(context)
        } catch (e: Exception) {
            // A launcher that is busy or gone; the next change redraws.
        }
        for (type in listOf(CountTile::class.java, PauseTile::class.java)) {
            try {
                TileService.requestListeningState(context, ComponentName(context, type))
            } catch (e: Exception) {
                // The tile was never added; nothing is listening.
            }
        }
    }

    private fun publishShortcuts(context: Context) {
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return
        fun shortcut(id: String, label: String, icon: Int, intent: Intent, rank: Int) =
            ShortcutInfo.Builder(context, id)
                .setShortLabel(label)
                .setIcon(Icon.createWithResource(context, icon))
                .setIntent(intent)
                .setRank(rank)
                .build()
        try {
            manager.dynamicShortcuts = listOf(
                shortcut(
                    "count",
                    label(context, "countOne", R.string.tile_count),
                    R.drawable.ic_shortcut_count,
                    Intent(context, ShortcutActivity::class.java).setAction(ACTION_COUNT),
                    0,
                ),
                shortcut(
                    "pause",
                    label(context, "pause", R.string.tile_pause),
                    R.drawable.ic_shortcut_pause,
                    Intent(context, ShortcutActivity::class.java).setAction(ACTION_PAUSE),
                    1,
                ),
                shortcut(
                    "library",
                    label(context, "library", R.string.shortcut_library),
                    R.drawable.ic_shortcut_library,
                    Intent(context, MainActivity::class.java).setAction(ACTION_LIBRARY),
                    2,
                ),
            )
        } catch (e: Exception) {
            // Rate limited or the user is locked; the shortcuts keep their last words.
        }
    }
}
