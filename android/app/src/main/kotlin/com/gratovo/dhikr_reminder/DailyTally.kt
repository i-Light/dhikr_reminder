package com.gratovo.dhikr_reminder

/**
 * How far each dhikr has got today, as the floating card needs it while the
 * Flutter app is not running. No Android in it, so it is tested on a plain JVM
 * (see DailyTallyTest).
 *
 * Two sources know about taps: this card counts the ones made on it, and the
 * app counts its own and, once it is opened, the card's too. The app sends its
 * totals down ([merge]); the card keeps whichever is larger for each dhikr, so
 * a count never goes backwards and the two sources agree again as soon as the
 * app has collected the card's taps.
 *
 * A tally belongs to one day. On a new day it is empty.
 */
object DailyTally {
    data class Tally(val day: String, val counts: Map<Int, Int>)

    /** What [stored] says about [today]: itself, or an empty tally if it is older. */
    private fun current(stored: Tally?, today: String): Tally =
        if (stored != null && stored.day == today) stored else Tally(today, emptyMap())

    /** How many times [dhikrId] has been said today. */
    fun count(stored: Tally?, today: String, dhikrId: Int): Int =
        current(stored, today).counts[dhikrId] ?: 0

    /** [stored] after one more tap on [dhikrId]. */
    fun add(stored: Tally?, today: String, dhikrId: Int): Tally {
        val tally = current(stored, today)
        return Tally(today, tally.counts + (dhikrId to (tally.counts[dhikrId] ?: 0) + 1))
    }

    /**
     * [stored] after the app reported [pushed] for [pushedDay]. A report for any
     * other day than [today] (a clock or time zone that disagrees) changes nothing.
     */
    fun merge(stored: Tally?, pushedDay: String, pushed: Map<Int, Int>, today: String): Tally {
        val tally = current(stored, today)
        if (pushedDay != today) return tally
        val merged = tally.counts.toMutableMap()
        for ((id, count) in pushed) {
            if (count > (merged[id] ?: 0)) merged[id] = count
        }
        return Tally(today, merged)
    }
}
