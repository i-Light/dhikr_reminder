package com.gratovo.dhikr_reminder

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

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
    private const val KEY_ARMED = "armed"
    private const val KEY_TAPS = "taps"

    data class Planned(
        val id: Int,
        val atMillis: Long,
        val dhikrId: Int,
        val text: String,
        val amount: Int,
    )

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun savePlan(
        context: Context,
        plan: List<Planned>,
        title: String,
        closeLabel: String,
        tip: String,
    ) {
        val array = JSONArray()
        for (p in plan) {
            array.put(
                JSONObject()
                    .put("id", p.id)
                    .put("at", p.atMillis)
                    .put("dhikrId", p.dhikrId)
                    .put("text", p.text)
                    .put("amount", p.amount),
            )
        }
        prefs(context).edit()
            .putString(KEY_PLAN, array.toString())
            .putString(KEY_TITLE, title)
            .putString(KEY_CLOSE, closeLabel)
            .putString(KEY_TIP, tip)
            .apply()
    }

    /** The card's texts alone, for a reminder shown outside the plan. */
    fun saveLabels(context: Context, title: String, closeLabel: String, tip: String) {
        prefs(context).edit()
            .putString(KEY_TITLE, title)
            .putString(KEY_CLOSE, closeLabel)
            .putString(KEY_TIP, tip)
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

    /** Alarm ids currently armed, so they can be cancelled by id later. */
    fun saveArmed(context: Context, ids: List<Int>) {
        prefs(context).edit().putString(KEY_ARMED, ids.joinToString(",")).apply()
    }

    fun armed(context: Context): List<Int> =
        (prefs(context).getString(KEY_ARMED, "") ?: "")
            .split(",")
            .mapNotNull { it.toIntOrNull() }

    /** One counted tap on [dhikrId], to be handed to Dart's statistics. */
    @Synchronized
    fun addTap(context: Context, dhikrId: Int) {
        val taps = JSONObject(prefs(context).getString(KEY_TAPS, "{}") ?: "{}")
        taps.put(dhikrId.toString(), taps.optInt(dhikrId.toString(), 0) + 1)
        prefs(context).edit().putString(KEY_TAPS, taps.toString()).apply()
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
