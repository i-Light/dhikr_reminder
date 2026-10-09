package com.gratovo.dhikr_reminder

import com.gratovo.dhikr_reminder.HealthRules.Event
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HealthRulesTest {
    private val minute = 60_000L
    private val now = 1_000_000_000_000L

    @Test
    fun theLogKeepsTheNewestEventsOnly() {
        var events = emptyList<Event>()
        for (i in 1..HealthRules.MAX_EVENTS + 10) events = HealthRules.append(events, Event(i.toLong(), "card"))

        assertEquals(HealthRules.MAX_EVENTS, events.size)
        assertEquals(11L, events.first().atMillis)
        assertEquals((HealthRules.MAX_EVENTS + 10).toLong(), events.last().atMillis)
    }

    @Test
    fun theLogSurvivesBeingSavedAndRead() {
        val events = listOf(Event(5, "card"), Event(9, "notification", "no overlay"))

        assertEquals(events, HealthRules.decode(HealthRules.encode(events)))
    }

    @Test
    fun aDetailCannotBreakTheFormat() {
        val read = HealthRules.decode(HealthRules.encode(listOf(Event(5, "error", "a|b\nc"))))

        assertEquals(1, read.size)
        assertEquals("a/b c", read.single().detail)
    }

    @Test
    fun damagedLinesAreSkippedNotFatal() {
        val read = HealthRules.decode("garbage\n7|card|ok\n|x|y\n8||z")

        assertEquals(listOf(Event(7, "card", "ok")), read)
        assertEquals(emptyList<Event>(), HealthRules.decode(null))
    }

    @Test
    fun remindersThatKeepArrivingAreNotStopped() {
        assertFalse(HealthRules.isStopped(now, 30 * minute, now - 40 * minute, 0, 10))
    }

    @Test
    fun noDeliveryForMoreThanTwoIntervalsIsStopped() {
        assertTrue(HealthRules.isStopped(now, 30 * minute, now - 66 * minute, 0, 10))
    }

    @Test
    fun aPhoneThatDozesIsAllowedToBeALittleLate() {
        // Just over two intervals, inside the grace.
        assertFalse(HealthRules.isStopped(now, 30 * minute, now - 63 * minute, 0, 10))
    }

    @Test
    fun aPauseIsNeverStopped() {
        assertFalse(HealthRules.isStopped(now, 30 * minute, now - 600 * minute, now + minute, 10))
    }

    @Test
    fun nothingArmedOrUnknownThingsAreNeverStopped() {
        assertFalse(HealthRules.isStopped(now, 30 * minute, now - 600 * minute, 0, 0))
        assertFalse(HealthRules.isStopped(now, 0, now - 600 * minute, 0, 10))
        assertFalse(HealthRules.isStopped(now, 30 * minute, 0, 0, 10))
    }
}
