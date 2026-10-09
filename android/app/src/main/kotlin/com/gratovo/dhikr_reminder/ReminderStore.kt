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
    private const val KEY_ARABIC_HIDDEN = "arabic_hidden"
    private const val KEY_ARABIC_CHANGED = "arabic_changed"
    private const val KEY_PAUSED_UNTIL = "paused_until"
    private const val KEY_OPEN_DHIKR = "open_dhikr"
    private const val KEY_QUIET_START = "quiet_start"
    private const val KEY_QUIET_END = "quiet_end"
    private const val KEY_EVENTS = "events"
    private const val KEY_LAST_FIRED = "last_fired"
    private const val KEY_ACTIVE_SINCE = "active_since"
    private const val KEY_FOCUS = "focus"
    private const val KEY_LABELS = "surface_labels"
    private const val KEY_PAUSE_CHANGED = "pause_changed"
    private const val KEY_OPEN_TAB = "open_tab"
    private const val KEY_SURFACES_STATE = "surfaces_state"

    data class Planned(
        val id: Int,
        val atMillis: Long,
        val dhikrId: Int,
        val text: String,
        val amount: Int,
        /** How many times a day this dhikr is meant to be said, or 0 for no goal. */
        val goal: Int = 0,
        /** The Latin-letter pronunciation shown under the Arabic, or empty for none. */
        val translit: String = "",
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
        pausedUntilMillis: Long = 0L,
        quietStart: Int = QuietWindow.OFF,
        quietEnd: Int = QuietWindow.OFF,
    ) {
        val p = prefs(context)
        val now = System.currentTimeMillis()
        // A pause or resume made from a tile or shortcut that the app has not
        // heard about yet outranks what the app sends, or the next sync would undo it.
        val pausedUntil = if (p.getBoolean(KEY_PAUSE_CHANGED, false)) {
            p.getLong(KEY_PAUSED_UNTIL, 0L)
        } else {
            pausedUntilMillis
        }
        // "Reminders have been meant to arrive since": the first plan ever, and
        // again whenever a pause is lifted, so neither reads as "stopped".
        val wasPaused = p.getLong(KEY_PAUSED_UNTIL, 0L) > 0L
        if (!p.contains(KEY_ACTIVE_SINCE) || (wasPaused && pausedUntil == 0L)) {
            p.edit().putLong(KEY_ACTIVE_SINCE, now).apply()
        }
        if (Features.SURFACES) {
            val before = focus(context)
            val after = SurfaceRules.pickFocus(before, plan, now)
            if (after != null && after != before) setFocus(context, after)
        }
        prefs(context).edit()
            .putString(KEY_PLAN, encode(plan))
            .putLong(KEY_INTERVAL, intervalMillis)
            .putLong(KEY_PAUSED_UNTIL, pausedUntil)
            .putInt(KEY_QUIET_START, quietStart)
            .putInt(KEY_QUIET_END, quietEnd)
            .putString(KEY_TITLE, title)
            .putString(KEY_CLOSE, closeLabel)
            .putString(KEY_TIP, tip)
            .putString(KEY_DAY_LABEL, dayLabel)
            .apply()
    }

    /**
     * Forgets the plan, the interval and any pause, so nothing that tops the
     * plan up (a reboot, an update, a fired reminder) can bring cancelled
     * reminders back.
     */
    fun clearPlan(context: Context) {
        prefs(context).edit()
            .remove(KEY_PLAN)
            .remove(KEY_INTERVAL)
            .remove(KEY_PAUSED_UNTIL)
            .apply()
    }

    fun quietStart(context: Context): Int = prefs(context).getInt(KEY_QUIET_START, QuietWindow.OFF)

    fun quietEnd(context: Context): Int = prefs(context).getInt(KEY_QUIET_END, QuietWindow.OFF)

    /** The end of the pause the person set, as millis since the epoch, or 0 for none. */
    fun pausedUntilMillis(context: Context): Long = prefs(context).getLong(KEY_PAUSED_UNTIL, 0L)

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
                    .put("goal", p.goal)
                    .put("translit", p.translit),
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
                    o.optString("translit", ""),
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
    fun addTap(context: Context, dhikrId: Int) = addTaps(context, dhikrId, 1)

    /** [count] counted taps on [dhikrId] at once (a "Done" on a notification). */
    @Synchronized
    fun addTaps(context: Context, dhikrId: Int, count: Int) {
        if (count <= 0) return
        val taps = JSONObject(prefs(context).getString(KEY_TAPS, "{}") ?: "{}")
        taps.put(dhikrId.toString(), taps.optInt(dhikrId.toString(), 0) + count)
        val tally = DailyTally.add(readTally(context), today(), dhikrId, count)
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

    /** Everything said today, all dhikr together, as far as the card knows. */
    @Synchronized
    fun todayTotal(context: Context): Int = DailyTally.total(readTally(context), today())

    /** The app's own totals for [day]; see [DailyTally.merge]. */
    @Synchronized
    fun setToday(context: Context, day: String, counts: Map<Int, Int>) {
        val merged = DailyTally.merge(readTally(context), day, counts, today())
        prefs(context).edit().putString(KEY_DAILY, writeTally(merged)).apply()
    }

    // ---- whether the card leaves the Arabic out -----------------------

    /** Whether the card shows the transliteration alone, leaving the Arabic out. */
    fun arabicHidden(context: Context): Boolean = prefs(context).getBoolean(KEY_ARABIC_HIDDEN, false)

    /** The app's own setting: it wins over, and so forgets, a change made on the card that was never collected. */
    @Synchronized
    fun setArabicHidden(context: Context, hidden: Boolean) {
        prefs(context).edit()
            .putBoolean(KEY_ARABIC_HIDDEN, hidden)
            .putBoolean(KEY_ARABIC_CHANGED, false)
            .apply()
    }

    /** The person pressed the card's Arabic button; the app is told next time it asks. */
    @Synchronized
    fun changeArabicHiddenFromCard(context: Context, hidden: Boolean) {
        prefs(context).edit()
            .putBoolean(KEY_ARABIC_HIDDEN, hidden)
            .putBoolean(KEY_ARABIC_CHANGED, true)
            .apply()
    }

    /** The value the card's button last set if the app has not heard of it yet, else null. */
    @Synchronized
    fun takeArabicChange(context: Context): Boolean? {
        val p = prefs(context)
        if (!p.getBoolean(KEY_ARABIC_CHANGED, false)) return null
        p.edit().putBoolean(KEY_ARABIC_CHANGED, false).apply()
        return p.getBoolean(KEY_ARABIC_HIDDEN, false)
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
            .put("translit", reminder.translit)
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
                    o.optString("translit", ""),
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

    // ---- what has happened to the reminders ---------------------------

    /** Adds one line to the rolling log of what happened to reminders. */
    @Synchronized
    fun log(context: Context, kind: String, detail: String = "") {
        val p = prefs(context)
        val events = HealthRules.append(
            HealthRules.decode(p.getString(KEY_EVENTS, null)),
            HealthRules.Event(System.currentTimeMillis(), kind, detail),
        )
        p.edit().putString(KEY_EVENTS, HealthRules.encode(events)).apply()
    }

    fun events(context: Context): List<HealthRules.Event> =
        HealthRules.decode(prefs(context).getString(KEY_EVENTS, null))

    /** A reminder reached the person (as a card, on the lock screen or as a notification). */
    fun markDelivered(context: Context) {
        prefs(context).edit().putLong(KEY_LAST_FIRED, System.currentTimeMillis()).apply()
    }

    fun lastDeliveredMillis(context: Context): Long = prefs(context).getLong(KEY_LAST_FIRED, 0L)

    /** The moment reminders were last meant to start (see [savePlan]). */
    fun activeSinceMillis(context: Context): Long = prefs(context).getLong(KEY_ACTIVE_SINCE, 0L)

    // ---- the dhikr a tapped notification asks the app to open ---------

    /** A tapped notification asks the app to open [dhikrId]; Dart takes it when it next asks. */
    @Synchronized
    fun setOpenDhikr(context: Context, dhikrId: Int) {
        prefs(context).edit().putInt(KEY_OPEN_DHIKR, dhikrId).apply()
    }

    /** The dhikr waiting to be opened, or null. Taking it forgets it. */
    @Synchronized
    fun takeOpenDhikr(context: Context): Int? {
        val p = prefs(context)
        if (!p.contains(KEY_OPEN_DHIKR)) return null
        val id = p.getInt(KEY_OPEN_DHIKR, -1)
        p.edit().remove(KEY_OPEN_DHIKR).apply()
        return if (id < 0) null else id
    }

    // ---- the extra ways to count (widget, tiles, shortcuts) -----------

    /** The dhikr "count one" adds to, or null before any reminder is known. */
    fun focus(context: Context): SurfaceRules.Focus? {
        val raw = prefs(context).getString(KEY_FOCUS, null) ?: return null
        return try {
            val o = JSONObject(raw)
            SurfaceRules.Focus(o.getInt("id"), o.getString("text"))
        } catch (e: Exception) {
            null
        }
    }

    fun setFocus(context: Context, focus: SurfaceRules.Focus) {
        val json = JSONObject().put("id", focus.dhikrId).put("text", focus.text)
        prefs(context).edit().putString(KEY_FOCUS, json.toString()).apply()
    }

    /** The words the surfaces show, in the app's language (see Surfaces.label). */
    fun surfaceLabels(context: Context): Map<String, String> {
        val raw = prefs(context).getString(KEY_LABELS, null) ?: return emptyMap()
        return try {
            val o = JSONObject(raw)
            o.keys().asSequence().associateWith { o.optString(it) }
        } catch (e: Exception) {
            emptyMap()
        }
    }

    /** Stores [labels]; true when they differ from what was there. */
    fun saveSurfaceLabels(context: Context, labels: Map<String, String>): Boolean {
        val json = JSONObject()
        for ((key, value) in labels.toSortedMap()) json.put(key, value)
        val text = json.toString()
        if (prefs(context).getString(KEY_LABELS, null) == text) return false
        prefs(context).edit().putString(KEY_LABELS, text).apply()
        return true
    }

    /**
     * A tile, shortcut or button paused the reminders ([untilMillis]) or lifted
     * the pause (0). The app is told next time it asks (see [takePauseChange]).
     */
    @Synchronized
    fun setPausedFromSurface(context: Context, untilMillis: Long) {
        val edit = prefs(context).edit()
            .putLong(KEY_PAUSED_UNTIL, untilMillis)
            .putBoolean(KEY_PAUSE_CHANGED, true)
        if (untilMillis == 0L) edit.putLong(KEY_ACTIVE_SINCE, System.currentTimeMillis())
        edit.apply()
    }

    /** The pause set outside the app since the app last asked (0 means lifted), or null. */
    @Synchronized
    fun takePauseChange(context: Context): Long? {
        val p = prefs(context)
        if (!p.getBoolean(KEY_PAUSE_CHANGED, false)) return null
        p.edit().putBoolean(KEY_PAUSE_CHANGED, false).apply()
        return p.getLong(KEY_PAUSED_UNTIL, 0L)
    }

    /** A launcher shortcut asks the app to show [tab]; Dart takes it when it next asks. */
    @Synchronized
    fun setOpenTab(context: Context, tab: String) {
        prefs(context).edit().putString(KEY_OPEN_TAB, tab).apply()
    }

    @Synchronized
    fun takeOpenTab(context: Context): String? {
        val p = prefs(context)
        val tab = p.getString(KEY_OPEN_TAB, null) ?: return null
        p.edit().remove(KEY_OPEN_TAB).apply()
        return tab
    }

    /** Whether the widget, tiles and shortcuts were last switched on (true) or off (false). */
    fun surfacesState(context: Context): Boolean = prefs(context).getBoolean(KEY_SURFACES_STATE, true)

    fun setSurfacesState(context: Context, on: Boolean) {
        prefs(context).edit().putBoolean(KEY_SURFACES_STATE, on).apply()
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
