package com.gratovo.dhikr_reminder

import com.gratovo.dhikr_reminder.DailyTally.Tally
import org.junit.Assert.assertEquals
import org.junit.Test

class DailyTallyTest {
    private val today = "2026-10-09"
    private val yesterday = "2026-10-08"

    @Test
    fun nothingStoredMeansNothingSaid() {
        assertEquals(0, DailyTally.count(null, today, 1))
    }

    @Test
    fun eachTapCountsForItsOwnDhikrOnly() {
        var tally: Tally? = null
        tally = DailyTally.add(tally, today, 1)
        tally = DailyTally.add(tally, today, 1)
        tally = DailyTally.add(tally, today, 2)
        assertEquals(2, DailyTally.count(tally, today, 1))
        assertEquals(1, DailyTally.count(tally, today, 2))
        assertEquals(0, DailyTally.count(tally, today, 3))
    }

    @Test
    fun aNewDayStartsFromZero() {
        val old = Tally(yesterday, mapOf(1 to 40))
        assertEquals(0, DailyTally.count(old, today, 1))
        val after = DailyTally.add(old, today, 1)
        assertEquals(today, after.day)
        assertEquals(1, DailyTally.count(after, today, 1))
    }

    @Test
    fun theAppsTotalsRaiseWhatTheCardHas() {
        val stored = Tally(today, mapOf(1 to 5, 2 to 9))
        val merged = DailyTally.merge(stored, today, mapOf(1 to 12, 3 to 4), today)
        assertEquals(12, DailyTally.count(merged, today, 1))
        assertEquals(9, DailyTally.count(merged, today, 2))
        assertEquals(4, DailyTally.count(merged, today, 3))
    }

    @Test
    fun aCountNeverGoesBackwards() {
        // The card counted 8 that the app has not collected yet; the app says 5.
        val stored = Tally(today, mapOf(1 to 8))
        val merged = DailyTally.merge(stored, today, mapOf(1 to 5), today)
        assertEquals(8, DailyTally.count(merged, today, 1))
    }

    @Test
    fun theAppAndTheCardAgreeOnceTheTapsAreCollected() {
        // The card counted 5. The app collects them (its total becomes 5) and reports it.
        val stored = Tally(today, mapOf(1 to 5))
        val merged = DailyTally.merge(stored, today, mapOf(1 to 5), today)
        assertEquals(5, DailyTally.count(merged, today, 1))
    }

    @Test
    fun aReportForAnotherDayIsIgnored() {
        val stored = Tally(today, mapOf(1 to 2))
        val merged = DailyTally.merge(stored, yesterday, mapOf(1 to 90), today)
        assertEquals(2, DailyTally.count(merged, today, 1))
    }

    @Test
    fun aReportOnANewDayStartsThatDay() {
        val stored = Tally(yesterday, mapOf(1 to 90))
        val merged = DailyTally.merge(stored, today, mapOf(2 to 3), today)
        assertEquals(today, merged.day)
        assertEquals(0, DailyTally.count(merged, today, 1))
        assertEquals(3, DailyTally.count(merged, today, 2))
    }
}
