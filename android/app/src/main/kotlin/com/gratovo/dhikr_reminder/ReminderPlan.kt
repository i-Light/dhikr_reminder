package com.gratovo.dhikr_reminder

/**
 * The arithmetic of keeping the reminder plan topped up, with no Android in it
 * so it can be tested on a plain JVM (see ReminderPlanTest).
 *
 * The plan Dart hands over covers about a day. If the app is not opened for
 * longer than that, the plan runs out and reminders would stop; [extend] lays
 * the stored reminders out again, after the last one, so they never do.
 */
object ReminderPlan {
    /** Below this many reminders still to come, the plan is extended. */
    const val MIN_AHEAD = 8

    /** How far ahead the extended plan reaches. */
    const val AHEAD_MILLIS = 24L * 60 * 60 * 1000

    /** At most this many reminders ahead, however short the interval. */
    const val MAX_AHEAD_COUNT = 64

    /** Reminders that already fired are kept this long, so one still being shown can be looked up. */
    const val KEEP_PAST_MILLIS = 60L * 60 * 1000

    /**
     * [plan] itself (the same instance) when nothing needs adding, or when it
     * cannot be extended (it is empty, or the interval is unknown). Otherwise a
     * new plan with enough reminders after [nowMillis].
     *
     * The stored plan is a weighted sample of the person's dhikr, so repeating
     * it in order keeps the mix. New reminders get ids above the largest one in
     * use, and start one [intervalMillis] after the later of the last reminder
     * and [nowMillis].
     */
    fun extend(
        plan: List<ReminderStore.Planned>,
        intervalMillis: Long,
        nowMillis: Long,
    ): List<ReminderStore.Planned> {
        if (plan.isEmpty() || intervalMillis <= 0) return plan

        val ahead = plan.count { it.atMillis > nowMillis }
        if (ahead >= MIN_AHEAD) return plan

        val wanted = (AHEAD_MILLIS / intervalMillis).toInt().coerceIn(MIN_AHEAD, MAX_AHEAD_COUNT)
        val extended = plan.filter { it.atMillis > nowMillis - KEEP_PAST_MILLIS }.toMutableList()
        var nextId = plan.maxOf { it.id } + 1
        var nextAt = maxOf(plan.maxOf { it.atMillis }, nowMillis) + intervalMillis
        for (added in 0 until (wanted - ahead)) {
            val pattern = plan[added % plan.size]
            extended.add(
                ReminderStore.Planned(
                    nextId++,
                    nextAt,
                    pattern.dhikrId,
                    pattern.text,
                    pattern.amount,
                    pattern.goal,
                    pattern.translit,
                ),
            )
            nextAt += intervalMillis
        }
        return extended
    }
}
