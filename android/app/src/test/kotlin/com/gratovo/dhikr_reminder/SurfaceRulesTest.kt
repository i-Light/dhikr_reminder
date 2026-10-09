package com.gratovo.dhikr_reminder

import com.gratovo.dhikr_reminder.DailyTally.Tally
import com.gratovo.dhikr_reminder.SurfaceRules.Focus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SurfaceRulesTest {
    private val now = 1_000_000L

    private fun planned(id: Int, at: Long, dhikrId: Int, text: String = "dhikr $dhikrId") =
        ReminderStore.Planned(id, at, dhikrId, text, 33)

    @Test
    fun nothingIsCountedBeforeAnyReminderIsKnown() {
        assertNull(SurfaceRules.pickFocus(null, emptyList(), now))
    }

    @Test
    fun theFirstPlanGivesTheNextDhikrDue() {
        val plan = listOf(planned(1, now - 5, 7), planned(2, now + 20, 8), planned(3, now + 10, 9))
        assertEquals(Focus(9, "dhikr 9"), SurfaceRules.pickFocus(null, plan, now))
    }

    @Test
    fun theDhikrStaysPutWhileItIsStillInThePlan() {
        val plan = listOf(planned(1, now + 10, 8), planned(2, now + 20, 9))
        assertEquals(Focus(9, "dhikr 9"), SurfaceRules.pickFocus(Focus(9, "old words"), plan, now))
    }

    @Test
    fun theWordsFollowTheLanguageButTheDhikrDoesNot() {
        val plan = listOf(planned(1, now + 10, 8, "new words"))
        assertEquals(Focus(8, "new words"), SurfaceRules.pickFocus(Focus(8, "old words"), plan, now))
    }

    @Test
    fun aDhikrThatLeftTheListIsReplaced() {
        val plan = listOf(planned(1, now + 10, 8))
        assertEquals(Focus(8, "dhikr 8"), SurfaceRules.pickFocus(Focus(5, "gone"), plan, now))
    }

    @Test
    fun anEmptyPlanKeepsWhatWasThere() {
        assertEquals(Focus(5, "kept"), SurfaceRules.pickFocus(Focus(5, "kept"), emptyList(), now))
    }

    @Test
    fun aPlanWhollyInThePastStillGivesADhikr() {
        val plan = listOf(planned(1, now - 20, 4), planned(2, now - 10, 6))
        assertEquals(Focus(4, "dhikr 4"), SurfaceRules.pickFocus(null, plan, now))
    }

    @Test
    fun theToggleStartsAnHourAndThenLiftsIt() {
        val started = SurfaceRules.pauseToggle(now, 0L)
        assertEquals(now + 60L * 60 * 1000, started)
        assertEquals(0L, SurfaceRules.pauseToggle(now + 1, started))
    }

    @Test
    fun aPauseThatEndedIsNoPauseSoTheToggleStartsANewOne() {
        assertEquals(now + SurfaceRules.PAUSE_MILLIS, SurfaceRules.pauseToggle(now, now - 1))
    }

    @Test
    fun laterBringsItBackInTenMinutes() {
        assertEquals(now + 10L * 60 * 1000, SurfaceRules.snoozeAt(now))
    }

    @Test
    fun aSnoozedDhikrIsNotBroughtBackAfterEveryReminderWasCancelled() {
        assertTrue(SurfaceRules.snoozeStillWanted(60_000L))
        assertFalse(SurfaceRules.snoozeStillWanted(0L))
    }

    @Test
    fun theTotalIsEverythingSaidToday() {
        val today = "2026-10-10"
        var tally: Tally? = null
        tally = DailyTally.add(tally, today, 1, 33)
        tally = DailyTally.add(tally, today, 2)
        assertEquals(34, DailyTally.total(tally, today))
        assertEquals(0, DailyTally.total(tally, "2026-10-11"))
        assertEquals(0, DailyTally.total(null, today))
    }
}
