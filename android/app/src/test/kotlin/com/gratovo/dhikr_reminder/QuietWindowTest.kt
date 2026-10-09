package com.gratovo.dhikr_reminder

import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class QuietWindowTest {
    private val night = 23 * 60 // 23:00
    private val morning = 6 * 60 // 06:00

    @Test
    fun aWindowAcrossMidnightHoldsBothSides() {
        assertTrue(QuietWindow.contains(23 * 60 + 30, night, morning))
        assertTrue(QuietWindow.contains(2 * 60, night, morning))
        assertFalse(QuietWindow.contains(12 * 60, night, morning))
    }

    @Test
    fun theEndsBelongToTheRightSide() {
        assertTrue(QuietWindow.contains(night, night, morning))
        assertFalse(QuietWindow.contains(morning, night, morning))
    }

    @Test
    fun aWindowInsideOneDayWorks() {
        assertTrue(QuietWindow.contains(13 * 60, 12 * 60, 14 * 60))
        assertFalse(QuietWindow.contains(15 * 60, 12 * 60, 14 * 60))
    }

    @Test
    fun noWindowIsEverQuiet() {
        assertFalse(QuietWindow.contains(0, QuietWindow.OFF, QuietWindow.OFF))
        assertFalse(QuietWindow.contains(0, night, night))
    }

    private val zone: ZoneId = ZoneOffset.UTC
    private fun at(hour: Int, minute: Int = 0) =
        LocalDateTime.of(2026, 1, 1, hour, minute).atZone(zone).toInstant().toEpochMilli()

    @Test
    fun theClockOfTheZoneDecides() {
        assertTrue(QuietWindow.containsMillis(at(1), night, morning, zone))
        assertFalse(QuietWindow.containsMillis(at(9), night, morning, zone))
    }

    @Test
    fun aToppedUpPlanSkipsTheQuietHours() {
        val minute = 60_000L
        val interval = 60 * minute
        val start = at(20)
        val plan = listOf(ReminderStore.Planned(1, start, 1, "a", 1))

        val extended = ReminderPlan.extend(plan, interval, start - interval, 0L, night, morning, zone)

        val added = extended.drop(1)
        assertTrue(added.isNotEmpty())
        assertTrue(added.none { QuietWindow.containsMillis(it.atMillis, night, morning, zone) })
        // The hours between 23:00 and 06:00 are skipped, not squeezed together:
        // the next reminder after 20:00 is the one at 21:00, and the one after
        // 22:00 is the one at 06:00.
        assertEquals(start + 60 * minute, added.first().atMillis)
        val afterNight = added.first { it.atMillis > at(22, 59) }
        assertEquals(at(6) + 24 * 60 * minute, afterNight.atMillis)
    }
}
