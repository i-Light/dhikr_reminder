package com.gratovo.dhikr_reminder

/**
 * Two small pieces of pure logic behind the "are my reminders still coming?"
 * check, with no Android in them so they run on a plain JVM (see
 * HealthRulesTest): the rolling event log, and the rule that decides reminders
 * have stopped.
 */
object HealthRules {
    /** One thing that happened to a reminder, for the log and for a bug report. */
    data class Event(val atMillis: Long, val kind: String, val detail: String = "")

    /** The log keeps this many events, newest last. */
    const val MAX_EVENTS = 40

    /** [events] with [event] added, oldest ones dropped past [MAX_EVENTS]. */
    fun append(events: List<Event>, event: Event): List<Event> =
        (events + event).takeLast(MAX_EVENTS)

    // One event per line, "millis|kind|detail". Plain text so it needs no JSON
    // library to test; the separator and newlines are taken out of the detail.
    fun encode(events: List<Event>): String =
        events.joinToString("\n") { "${it.atMillis}|${clean(it.kind)}|${clean(it.detail)}" }

    fun decode(raw: String?): List<Event> =
        (raw ?: "").lineSequence().mapNotNull { line ->
            val parts = line.split("|", limit = 3)
            val at = parts.getOrNull(0)?.toLongOrNull() ?: return@mapNotNull null
            val kind = parts.getOrNull(1)?.takeIf { it.isNotEmpty() } ?: return@mapNotNull null
            Event(at, kind, parts.getOrNull(2) ?: "")
        }.toList()

    private fun clean(text: String) = text.replace('|', '/').replace('\n', ' ').replace('\r', ' ')

    /** How late a reminder may be before it counts as missing, beyond two intervals. */
    const val GRACE_MILLIS = 5L * 60 * 1000

    /**
     * Whether reminders have stopped coming: some are armed, no pause is on, and
     * nothing has been delivered for more than two intervals (plus a grace)
     * since the later of the last delivery, the moment reminders started, and
     * the moment a pause ended. A phone that dozes can be late by a few minutes,
     * hence two intervals and not one.
     *
     * [sinceMillis] is that later moment: the caller passes the maximum of the
     * last delivery, when reminders were first planned and when the last pause
     * ended, so a pause or a fresh install never reads as "stopped".
     */
    fun isStopped(
        nowMillis: Long,
        intervalMillis: Long,
        sinceMillis: Long,
        pausedUntilMillis: Long,
        armedCount: Int,
    ): Boolean {
        if (armedCount <= 0 || intervalMillis <= 0 || sinceMillis <= 0) return false
        if (pausedUntilMillis > nowMillis) return false
        return nowMillis - sinceMillis > 2 * intervalMillis + GRACE_MILLIS
    }
}
