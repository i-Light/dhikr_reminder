package com.gratovo.dhikr_reminder

/**
 * The arithmetic behind the extra ways to count without opening the app (the
 * home-screen widget, the quick-settings tiles, the launcher shortcuts and the
 * buttons on a reminder notification). No Android in it, so it is tested on a
 * plain JVM (see SurfaceRulesTest).
 */
object SurfaceRules {
    /** How long "pause" holds the reminders back. */
    const val PAUSE_MILLIS = 60L * 60 * 1000

    /** How long "later" on a notification waits before the same dhikr comes again. */
    const val SNOOZE_MILLIS = 10L * 60 * 1000

    /** The dhikr that "count one" adds to, with the words to show for it. */
    data class Focus(val dhikrId: Int, val text: String)

    /**
     * The dhikr the widget and the tile count. It is whichever one the person was
     * last reminded of ([current], set when a reminder is delivered), and it stays
     * put between reminders so the widget does not change under a thumb. It is
     * only replaced when nothing is known yet, or when that dhikr has left the
     * person's list (it is no longer in [plan]); then the next reminder due is
     * used. An empty plan changes nothing.
     */
    fun pickFocus(current: Focus?, plan: List<ReminderStore.Planned>, nowMillis: Long): Focus? {
        if (plan.isEmpty()) return current
        val same = plan.firstOrNull { it.dhikrId == current?.dhikrId }
        // Same dhikr, but the words may have changed with the app's language.
        if (current != null && same != null) return Focus(current.dhikrId, same.text)
        val next = plan.filter { it.atMillis > nowMillis }.minByOrNull { it.atMillis } ?: plan.first()
        return Focus(next.dhikrId, next.text)
    }

    /**
     * What the pause toggle sets: 0 (resume) while a pause is on at [nowMillis],
     * otherwise the moment an hour from now.
     */
    fun pauseToggle(nowMillis: Long, pausedUntilMillis: Long): Long =
        if (PendingRules.isPaused(nowMillis, pausedUntilMillis)) 0L else nowMillis + PAUSE_MILLIS

    fun snoozeAt(nowMillis: Long): Long = nowMillis + SNOOZE_MILLIS

    /**
     * Whether a "later" that fires at [nowMillis] should still bring the dhikr
     * back: not if the person has cancelled every reminder meanwhile (no
     * interval is stored then).
     */
    fun snoozeStillWanted(intervalMillis: Long): Boolean = intervalMillis > 0
}
