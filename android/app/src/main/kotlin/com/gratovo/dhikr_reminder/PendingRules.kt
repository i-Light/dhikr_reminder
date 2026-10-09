package com.gratovo.dhikr_reminder

/**
 * The rules for a reminder that arrives while the phone is locked, with no
 * Android in them so they can be tested on a plain JVM (see PendingRulesTest).
 *
 * What the person asked for: when a reminder is due and the phone is locked, the
 * card lights the screen for 30 seconds, then the screen is let go back to sleep.
 * The reminder is not forgotten, though. It waits, and shows again (as the usual
 * card over other apps) every time the phone is next unlocked, until the dhikr
 * is counted through or the card is closed with its cross.
 */
object PendingRules {
    /** How long the card stays lit on the lock screen when nobody touches it. */
    const val LOCKSCREEN_MILLIS = 30_000L

    /** A reminder nobody got to is let go after this long. */
    const val MAX_AGE_MILLIS = 12L * 60 * 60 * 1000

    /**
     * How long to wait for the lock-screen card to prove it started. Some phones
     * refuse an activity launched from the background without saying so; if it
     * has not started by then the reminder arrives as a notification instead.
     */
    const val LAUNCH_CHECK_MILLIS = 2_500L

    /** How long the CPU is kept awake while the lock-screen card is being started. */
    const val WAKE_HOLD_MILLIS = 15_000L

    /**
     * Whether the phone counts as locked for a reminder arriving now: the screen
     * is off, or it is on but showing the lock screen.
     */
    fun isLocked(interactive: Boolean, keyguardLocked: Boolean): Boolean =
        !interactive || keyguardLocked

    /**
     * Whether a reminder saved at [savedAtMillis] is too old to show at
     * [nowMillis]. A clock that went backwards by more than the limit counts as
     * too old as well, since there is no telling how long ago it really was.
     */
    fun isExpired(savedAtMillis: Long, nowMillis: Long): Boolean {
        val age = nowMillis - savedAtMillis
        return age > MAX_AGE_MILLIS || age < -MAX_AGE_MILLIS
    }

    /** Whether the lock-screen card started after it was asked for. */
    fun lockScreenStarted(requestedAtMillis: Long, shownAtMillis: Long): Boolean =
        requestedAtMillis > 0 && shownAtMillis >= requestedAtMillis

    /** Whether reminders are paused at [nowMillis]; 0 or a past time means no pause. */
    fun isPaused(nowMillis: Long, pausedUntilMillis: Long): Boolean =
        pausedUntilMillis > nowMillis

    /**
     * Whether a floating card is welcome now: not during Do Not Disturb (any
     * mode that silences the phone) and not during a call. [interruptionFilter]
     * is `NotificationManager.currentInterruptionFilter` (1 all, 2 priority only,
     * 3 none, 4 alarms only, 0 unknown), [audioMode] is `AudioManager.getMode()`
     * (0 normal, 1 ringing, 2 in a call, 3 in a communication app call).
     */
    fun cardIsWelcome(interruptionFilter: Int, audioMode: Int): Boolean {
        val silenced = interruptionFilter in 2..4
        val inCall = audioMode in 1..3
        return !silenced && !inCall
    }
}
