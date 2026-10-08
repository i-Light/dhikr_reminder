package com.gratovo.dhikr_reminder

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate

/**
 * What the overlay needs to know while the Flutter app is not running: the plan
 * Dart handed over (which dhikr to show when), a few labels, and the taps made
 * on the overlay that Dart has not collected yet.
 *
 * Plain SharedPreferences of our own, not Flutter's: the overlay must work
 * without an engine.
 */
object ReminderStore {
    private const val PREFS = "dhikr_overlay"
    private const val KEY_PLAN = "plan"
    private const val KEY_TITLE = "title"
    private const val KEY_CLOSE = "close"
    private const val KEY_TIP = "tip"
    private const val KEY_DAY_LABEL = "day_label"
    private const val KEY_DAILY = "daily"
    private const val KEY_ARMED = "armed"
    private const val KEY_TAPS = "taps"
    private const val KEY_INTERVAL = "interval"
    private const val KEY_PENDING = "pending"
    private const val KEY_LOCK_REQUESTED = "lock_requested"
    private const val KEY_LOCK_SHOWN = "lock_shown"

    data class Planned(
        val id: Int,
        val atMillis: Long,
        val dhikrId: Int,
        val text: String,
        val amount: Int,
        /** How many times a day this dhikr is meant to be said, or 0 for no goal. */
        val goal: Int = 0,
    )

    /**
     * A reminder that came while the phone was locked and has not been counted
     * through yet. [count] is how far the person got, so the card can carry on
     * from there; [savedAt] is when it arrived, so a stale one can be dropped.
     */
    data class Pending(val reminder: Planned, val count: Int, val savedAt: Long)

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun savePlan(
        context: Context,
        plan: List<Planned>,
        intervalMillis: Long,
        title: String,
        closeLabel: String,
        tip: String,
        dayLabel: String,
    ) {
        prefs(context).edit()
            .putString(KEY_PLAN, encode(plan))
            .putLong(KEY_INTERVAL, intervalMillis)
            .putString(KEY_TITLE, title)
            .putString(KEY_CLOSE, closeLabel)
            .putString(KEY_TIP, tip)
            .putString(KEY_DAY_LABEL, dayLabel)
            .apply()
    }

    /** Replaces the plan alone, keeping the labels and the interval Dart handed over. */
    fun replacePlan(context: Context, plan: List<Planned>) {
        prefs(context).edit().putString(KEY_PLAN, encode(plan)).apply()
    }

    private fun encode(plan: List<Planned>): String {
        val array = JSONArray()
        for (p in plan) {
            array.put(
                JSONObject()
                    .put("id", p.id)
                    .put("at", p.atMillis)
                    .put("dhikrId", p.dhikrId)
                    .put("text", p.text)
                    .put("amount", p.amount)
                    .put("goal", p.goal),
            )
        }
        return array.toString()
    }

    /** The gap between two reminders, as the person set it. Zero when unknown. */
    fun intervalMillis(context: Context): Long = prefs(context).getLong(KEY_INTERVAL, 0L)

    /** The card's texts alone, for a reminder shown outside the plan. */
    fun saveLabels(context: Context, title: String, closeLabel: String, tip: String, dayLabel: String) {
        prefs(context).edit()
            .putString(KEY_TITLE, title)
            .putString(KEY_CLOSE, closeLabel)
            .putString(KEY_TIP, tip)
            .putString(KEY_DAY_LABEL, dayLabel)
            .apply()
    }

    fun plan(context: Context): List<Planned> {
        val raw = prefs(context).getString(KEY_PLAN, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            List(array.length()) { i ->
                val o = array.getJSONObject(i)
                Planned(
                    o.getInt("id"),
                    o.getLong("at"),
                    o.getInt("dhikrId"),
                    o.getString("text"),
                    o.getInt("amount"),
                    o.optInt("goal", 0),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun find(context: Context, id: Int): Planned? = plan(context).firstOrNull { it.id == id }

    fun title(context: Context): String = prefs(context).getString(KEY_TITLE, "") ?: ""

    fun closeLabel(context: Context): String = prefs(context).getString(KEY_CLOSE, "") ?: ""

    fun tip(context: Context): String = prefs(context).getString(KEY_TIP, "") ?: ""

    /** The label under the day counter on a card whose dhikr has a daily goal. */
    fun dayLabel(context: Context): String = prefs(context).getString(KEY_DAY_LABEL, "") ?: ""

    /** Alarm ids currently armed, so they can be cancelled by id later. */
    fun saveArmed(context: Context, ids: List<Int>) {
        prefs(context).edit().putString(KEY_ARMED, ids.joinToString(",")).apply()
    }

    fun armed(context: Context): List<Int> =
        (prefs(context).getString(KEY_ARMED, "") ?: "")
            .split(",")
            .mapNotNull { it.toIntOrNull() }

    /**
     * One counted tap on [dhikrId]: kept to be handed to the app's statistics,
     * and added to today's tally so the card can show how far the dhikr has got.
     */
    @Synchronized
    fun addTap(context: Context, dhikrId: Int) {
        val taps = JSONObject(prefs(context).getString(KEY_TAPS, "{}") ?: "{}")
        taps.put(dhikrId.toString(), taps.optInt(dhikrId.toString(), 0) + 1)
        val tally = DailyTally.add(readTally(context), today(), dhikrId)
        prefs(context).edit()
            .putString(KEY_TAPS, taps.toString())
            .putString(KEY_DAILY, writeTally(tally))
            .apply()
    }

    // ---- how far each dhikr has got today ---------------------------

    private fun today(): String = LocalDate.now().toString()

    private fun readTally(context: Context): DailyTally.Tally? {
        val raw = prefs(context).getString(KEY_DAILY, null) ?: return null
        return try {
            val o = JSONObject(raw)
            val counts = o.getJSONObject("counts")
            val map = HashMap<Int, Int>()
            for (key in counts.keys()) key.toIntOrNull()?.let { map[it] = counts.optInt(key, 0) }
            DailyTally.Tally(o.getString("day"), map)
        } catch (e: Exception) {
            null
        }
    }

    private fun writeTally(tally: DailyTally.Tally): String {
        val counts = JSONObject()
        for ((id, count) in tally.counts) counts.put(id.toString(), count)
        return JSONObject().put("day", tally.day).put("counts", counts).toString()
    }

    /** How many times [dhikrId] has been said today, as far as the card knows. */
    @Synchronized
    fun dailyCount(context: Context, dhikrId: Int): Int =
        DailyTally.count(readTally(context), today(), dhikrId)

    /** The app's own totals for [day]; see [DailyTally.merge]. */
    @Synchronized
    fun setToday(context: Context, day: String, counts: Map<Int, Int>) {
        val merged = DailyTally.merge(readTally(context), day, counts, today())
        prefs(context).edit().putString(KEY_DAILY, writeTally(merged)).apply()
    }

    // ---- the reminder waiting for the next unlock ---------------------

    /** Makes [reminder] the one waiting, in place of any earlier one. */
    @Synchronized
    fun setPending(context: Context, reminder: Planned, nowMillis: Long) {
        val json = JSONObject()
            .put("id", reminder.id)
            .put("dhikrId", reminder.dhikrId)
            .put("text", reminder.text)
            .put("amount", reminder.amount)
            .put("goal", reminder.goal)
            .put("count", 0)
            .put("savedAt", nowMillis)
        prefs(context).edit().putString(KEY_PENDING, json.toString()).apply()
    }

    /**
     * The reminder that is waiting, or null if none is. One that has waited too
     * long (see [PendingRules.isExpired]) is forgotten here and null is returned.
     */
    @Synchronized
    fun pending(context: Context, nowMillis: Long): Pending? {
        val raw = prefs(context).getString(KEY_PENDING, null) ?: return null
        return try {
            val o = JSONObject(raw)
            val savedAt = o.getLong("savedAt")
            if (PendingRules.isExpired(savedAt, nowMillis)) {
                clearPending(context)
                return null
            }
            Pending(
                Planned(
                    o.getInt("id"),
                    0L,
                    o.getInt("dhikrId"),
                    o.getString("text"),
                    o.getInt("amount"),
                    o.optInt("goal", 0),
                ),
                o.optInt("count", 0),
                savedAt,
            )
        } catch (e: Exception) {
            clearPending(context)
            null
        }
    }

    /** Remembers how far the waiting reminder was counted. Nothing waiting, nothing to do. */
    @Synchronized
    fun updatePendingCount(context: Context, count: Int) {
        val raw = prefs(context).getString(KEY_PENDING, null) ?: return
        try {
            val json = JSONObject(raw).put("count", count)
            prefs(context).edit().putString(KEY_PENDING, json.toString()).apply()
        } catch (e: Exception) {
            clearPending(context)
        }
    }

    @Synchronized
    fun clearPending(context: Context) {
        prefs(context).edit().remove(KEY_PENDING).apply()
    }

    // ---- did the lock-screen card start? ------------------------------

    fun setLockScreenRequested(context: Context, atMillis: Long) {
        prefs(context).edit().putLong(KEY_LOCK_REQUESTED, atMillis).commit()
    }

    fun setLockScreenShown(context: Context, atMillis: Long) {
        prefs(context).edit().putLong(KEY_LOCK_SHOWN, atMillis).commit()
    }

    /** Whether the lock-screen card started since it was last asked for. */
    fun lockScreenStarted(context: Context): Boolean {
        val p = prefs(context)
        return PendingRules.lockScreenStarted(
            p.getLong(KEY_LOCK_REQUESTED, 0L),
            p.getLong(KEY_LOCK_SHOWN, 0L),
        )
    }

    /** Returns every tap counted since the last call, and forgets them. */
    @Synchronized
    fun drainTaps(context: Context): Map<Int, Int> {
        val taps = JSONObject(prefs(context).getString(KEY_TAPS, "{}") ?: "{}")
        prefs(context).edit().remove(KEY_TAPS).apply()
        val result = HashMap<Int, Int>()
        for (key in taps.keys()) {
            key.toIntOrNull()?.let { result[it] = taps.optInt(key, 0) }
        }
        return result
    }
}
