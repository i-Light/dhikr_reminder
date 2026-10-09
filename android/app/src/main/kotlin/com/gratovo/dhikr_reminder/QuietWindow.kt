package com.gratovo.dhikr_reminder

import java.time.Instant
import java.time.ZoneId

/**
 * The daily window in which no reminder is shown, with no Android in it so it
 * runs on a plain JVM (see QuietWindowTest). Both ends are minutes after
 * midnight on the phone's clock; the window may cross midnight; a start equal
 * to the end, or a negative start, means there is no window.
 */
object QuietWindow {
    const val OFF = -1

    fun contains(minuteOfDay: Int, startMinutes: Int, endMinutes: Int): Boolean {
        if (startMinutes < 0 || endMinutes < 0 || startMinutes == endMinutes) return false
        return if (startMinutes < endMinutes) {
            minuteOfDay in startMinutes until endMinutes
        } else {
            minuteOfDay >= startMinutes || minuteOfDay < endMinutes
        }
    }

    /** Whether [atMillis] falls inside the window on the clock of [zone]. */
    fun containsMillis(
        atMillis: Long,
        startMinutes: Int,
        endMinutes: Int,
        zone: ZoneId = ZoneId.systemDefault(),
    ): Boolean {
        val time = Instant.ofEpochMilli(atMillis).atZone(zone).toLocalTime()
        return contains(time.hour * 60 + time.minute, startMinutes, endMinutes)
    }
}
