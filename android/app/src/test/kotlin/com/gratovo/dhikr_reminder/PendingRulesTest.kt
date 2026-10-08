package com.gratovo.dhikr_reminder

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PendingRulesTest {
    private val hour = 60L * 60 * 1000
    private val now = 1_800_000_000_000L

    @Test
    fun aPhoneWithTheScreenOffIsLocked() {
        assertTrue(PendingRules.isLocked(interactive = false, keyguardLocked = false))
        assertTrue(PendingRules.isLocked(interactive = false, keyguardLocked = true))
    }

    @Test
    fun aPhoneShowingTheLockScreenIsLocked() {
        assertTrue(PendingRules.isLocked(interactive = true, keyguardLocked = true))
    }

    @Test
    fun aPhoneInUseIsNotLocked() {
        assertFalse(PendingRules.isLocked(interactive = true, keyguardLocked = false))
    }

    @Test
    fun theLockScreenCardStaysLitForThirtySeconds() {
        assertEquals(30_000L, PendingRules.LOCKSCREEN_MILLIS)
    }

    @Test
    fun aFreshReminderHasNotExpired() {
        assertFalse(PendingRules.isExpired(now, now))
        assertFalse(PendingRules.isExpired(now - hour, now))
        assertFalse(PendingRules.isExpired(now - PendingRules.MAX_AGE_MILLIS, now))
    }

    @Test
    fun aReminderNobodyGotToForHalfADayExpires() {
        assertTrue(PendingRules.isExpired(now - PendingRules.MAX_AGE_MILLIS - 1, now))
        assertTrue(PendingRules.isExpired(now - 3 * 24 * hour, now))
    }

    @Test
    fun aClockSetFarBackwardsCountsAsExpired() {
        assertTrue(PendingRules.isExpired(now + PendingRules.MAX_AGE_MILLIS + 1, now))
    }

    @Test
    fun aSmallClockStepBackwardsDoesNot() {
        assertFalse(PendingRules.isExpired(now + 5 * 60 * 1000, now))
    }

    @Test
    fun theLockScreenCardCountsAsStartedOnlyIfItWasAskedForFirst() {
        assertFalse(PendingRules.lockScreenStarted(requestedAtMillis = 0, shownAtMillis = 0))
        assertFalse(PendingRules.lockScreenStarted(requestedAtMillis = now, shownAtMillis = now - 1))
        assertTrue(PendingRules.lockScreenStarted(requestedAtMillis = now, shownAtMillis = now))
        assertTrue(PendingRules.lockScreenStarted(requestedAtMillis = now, shownAtMillis = now + 800))
    }

    @Test
    fun anEarlierShowingDoesNotCountForALaterRequest() {
        val firstRequest = now
        val firstShown = now + 400
        val secondRequest = now + 10 * 60 * 1000
        assertTrue(PendingRules.lockScreenStarted(firstRequest, firstShown))
        assertFalse(PendingRules.lockScreenStarted(secondRequest, firstShown))
    }

    @Test
    fun theWaitForTheCardToStartIsShorterThanTheCardStaysUp() {
        assertTrue(PendingRules.LAUNCH_CHECK_MILLIS < PendingRules.LOCKSCREEN_MILLIS)
    }
}
