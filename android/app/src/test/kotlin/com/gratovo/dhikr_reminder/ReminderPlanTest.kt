package com.gratovo.dhikr_reminder

import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class ReminderPlanTest {
    private val minute = 60_000L
    private val now = 1_000_000_000_000L

    private fun reminder(id: Int, atMillis: Long, dhikrId: Int = id) =
        ReminderStore.Planned(id, atMillis, dhikrId, "dhikr $dhikrId", 33)

    /** A plan of [count] reminders, the first one [interval] after [now], like the one Dart sends. */
    private fun plan(count: Int, interval: Long = 30 * minute) =
        List(count) { reminder(it + 1, now + (it + 1) * interval) }

    @Test
    fun anEmptyPlanIsLeftAlone() {
        val empty = emptyList<ReminderStore.Planned>()
        assertSame(empty, ReminderPlan.extend(empty, 30 * minute, now))
    }

    @Test
    fun anUnknownIntervalLeavesThePlanAlone() {
        val plan = plan(2)
        assertSame(plan, ReminderPlan.extend(plan, 0, now))
    }

    @Test
    fun aPlanWithEnoughAheadIsLeftAlone() {
        val plan = plan(ReminderPlan.MIN_AHEAD)
        assertSame(plan, ReminderPlan.extend(plan, 30 * minute, now))
    }

    @Test
    fun aRunningLowPlanIsExtendedToADayAhead() {
        val interval = 30 * minute
        val plan = plan(3, interval)

        val extended = ReminderPlan.extend(plan, interval, now)

        // 24 h at 30 min is 48 reminders ahead in all.
        assertEquals(48, extended.count { it.atMillis > now })
        // The old ones are kept as they were.
        assertEquals(plan, extended.take(3))
        // The new ones carry on from the last, one interval apart.
        val added = extended.drop(3)
        assertEquals(plan.last().atMillis + interval, added.first().atMillis)
        added.zipWithNext().forEach { (a, b) -> assertEquals(interval, b.atMillis - a.atMillis) }
    }

    @Test
    fun newRemindersGetFreshIdsAndRepeatTheStoredOnesInOrder() {
        val plan = plan(3)

        val added = ReminderPlan.extend(plan, 30 * minute, now).drop(3)

        assertEquals((4..48).toList(), added.map { it.id })
        assertEquals(listOf(1, 2, 3, 1, 2, 3), added.take(6).map { it.dhikrId })
        assertTrue(added.all { it.amount == 33 })
    }

    @Test
    fun theTransliterationCarriesOverToTheNewReminders() {
        val plan = listOf(
            ReminderStore.Planned(1, now + 30 * minute, 1, "dhikr", 33, 0, "latin one"),
            ReminderStore.Planned(2, now + 60 * minute, 2, "other", 3, 0, ""),
        )

        val added = ReminderPlan.extend(plan, 30 * minute, now).drop(2)

        assertEquals(listOf("latin one", "", "latin one", ""), added.take(4).map { it.translit })
    }

    @Test
    fun aPlanThatRanOutStartsAgainOneIntervalFromNow() {
        val interval = 30 * minute
        // Every reminder is days old.
        val stale = List(5) { reminder(it + 1, now - 3 * 24 * 60 * minute + it * interval) }

        val extended = ReminderPlan.extend(stale, interval, now)

        assertEquals(now + interval, extended.minOf { it.atMillis })
        assertEquals(48, extended.size)
    }

    @Test
    fun aReminderThatJustFiredIsKeptSoItCanStillBeShown() {
        val interval = 30 * minute
        val justFired = reminder(1, now - 5 * minute)
        val longGone = reminder(2, now - 5 * 60 * minute)
        val coming = reminder(3, now + interval)

        val extended = ReminderPlan.extend(listOf(justFired, longGone, coming), interval, now)

        assertTrue(extended.contains(justFired))
        assertTrue(!extended.contains(longGone))
    }

    @Test
    fun aShortIntervalIsCappedSoThePlanStaysSmall() {
        val extended = ReminderPlan.extend(plan(1, minute), minute, now)

        assertEquals(ReminderPlan.MAX_AHEAD_COUNT, extended.count { it.atMillis > now })
    }

    @Test
    fun aLongIntervalStillGetsAFewAhead() {
        val sixHours = 6 * 60 * minute

        val extended = ReminderPlan.extend(plan(1, sixHours), sixHours, now)

        assertEquals(ReminderPlan.MIN_AHEAD, extended.count { it.atMillis > now })
    }

    @Test
    fun aPausedPlanIsExtendedAfterThePauseNotInsideIt() {
        val interval = 30 * minute
        val pausedUntil = now + 10 * 60 * minute
        val plan = plan(3, interval)

        val added = ReminderPlan.extend(plan, interval, now, pausedUntil).drop(3)

        assertTrue(added.isNotEmpty())
        assertTrue(added.all { it.atMillis > pausedUntil })
    }

    @Test
    fun anEmptiedPlanStaysEmptyWhenToppedUp() {
        // What cancel leaves behind: no plan and no interval. A reboot or a
        // fired reminder tops up from that, and must not bring reminders back.
        val empty = emptyList<ReminderStore.Planned>()

        assertSame(empty, ReminderPlan.extend(empty, 0, now, 0))
        assertEquals(0L, ReminderPlan.nextDue(empty, now))
    }

    @Test
    fun theNextDueReminderSkipsThePastAndThePause() {
        val plan = plan(4, 30 * minute)

        assertEquals(now + 30 * minute, ReminderPlan.nextDue(plan, now))
        assertEquals(now + 90 * minute, ReminderPlan.nextDue(plan, now, now + 70 * minute))
        assertEquals(0L, ReminderPlan.nextDue(plan, now + 10 * 60 * minute))
    }
}
