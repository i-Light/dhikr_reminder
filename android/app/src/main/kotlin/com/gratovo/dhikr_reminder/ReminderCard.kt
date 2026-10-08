package com.gratovo.dhikr_reminder

import android.animation.ArgbEvaluator
import android.animation.TimeInterpolator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import android.view.animation.OvershootInterpolator
import android.view.animation.PathInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * One dhikr as a card: the phone's version of the Windows reminder popup, with
 * the same look. The app icon and title, the dhikr in Ali Meshref with a golden
 * glow, a counter whose frame fills as you count, a "touch anywhere to count"
 * hint, and a green confetti finish. Tap the card to count, the cross to close it.
 *
 * The card is only the view and what happens inside it. Where it is put on
 * screen is the host's business: [OverlayService] floats it over other apps,
 * and [LockScreenReminderActivity] shows it over the lock screen. The host
 * hears about taps and endings through [Listener].
 */
class ReminderCard(
    private val context: Context,
    reminder: ReminderStore.Planned,
    startCount: Int,
    private val listener: Listener,
) {
    interface Listener {
        /** A tap was counted; [count] is how many so far. */
        fun onTap(count: Int)

        /** The target was reached; the finish animation starts. */
        fun onFinished()

        /** The cross was pressed. */
        fun onClose()

        /** The finished card has stayed up long enough to be taken away. */
        fun onDone()
    }

    private val handler = Handler(Looper.getMainLooper())
    private val evaluator = ArgbEvaluator()

    private val dhikrId = reminder.dhikrId
    private val amount = reminder.amount.coerceAtLeast(1)

    /** The daily goal, or 0 when this dhikr has none (and no day counter is shown). */
    private val goal = reminder.goal.coerceAtLeast(0)

    /** How many times this dhikr, and only this one, has been said today. */
    private var dayCount = if (goal > 0) ReminderStore.dailyCount(context, reminder.dhikrId) else 0
    private var count = startCount.coerceIn(0, amount - 1)
    private var released = false

    private val background: GradientDrawable
    private val titleView: TextView
    private val closeView: TextView
    private val dayNumber: TextView
    private val dayChip: LinearLayout
    private val dhikrView: TextView
    private val pill: CounterPill
    private val tipRow: View
    private val tipIcon: ImageView
    private val tipText: TextView
    private val confetti: ConfettiView

    private var accent = NORMAL_ACCENT
    private var doneFraction = 0f
    private var glowFlash = 0f
    private var strokeBoost = 0f

    /** The card itself, ready to be added to a window. Starts invisible: call [animateIn]. */
    val view: View

    init {
        val cream = Color.parseColor("#F6E7C8")
        val arabic = try {
            Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/NotoSansArabic-Variable.ttf")
        } catch (e: Exception) {
            Typeface.DEFAULT
        }

        // Header: the app icon, the title, the cross.
        val logo = ImageView(context).apply {
            setImageResource(R.mipmap.ic_launcher_foreground)
            // A flat white silhouette, like the desktop card's.
            setColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN)
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        titleView = TextView(context).apply {
            text = ReminderStore.title(context)
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }
        closeView = TextView(context).apply {
            text = "✕"
            contentDescription = ReminderStore.closeLabel(context)
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setPadding(dp(12), dp(4), dp(4), dp(4))
            setOnClickListener { listener.onClose() }
        }
        // Today's count for this dhikr, in the dhikr's own colour (the gold of
        // the accent is lost against the card's gold fill).
        dayNumber = TextView(context).apply {
            setTextColor(cream)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            maxLines = 1
        }
        val dayLabel = TextView(context).apply {
            text = ReminderStore.dayLabel(context)
            setTextColor(Color.argb(204, Color.red(cream), Color.green(cream), Color.blue(cream)))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            gravity = Gravity.CENTER
            maxLines = 1
        }
        dayChip = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            visibility = if (goal > 0) View.VISIBLE else View.GONE
            addView(dayNumber)
            addView(dayLabel)
        }
        val header = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(logo, LinearLayout.LayoutParams(dp(44), dp(44)).apply {
                marginEnd = dp(4)
            })
            addView(titleView, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            addView(dayChip, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { marginStart = dp(8) })
            addView(closeView)
        }

        // The dhikr, as large as fits.
        dhikrView = TextView(context).apply {
            this.text = reminder.text
            typeface = arabic
            setTextColor(cream)
            gravity = Gravity.CENTER
            textDirection = View.TEXT_DIRECTION_RTL
            setLineSpacing(0f, 1.45f)
            if (Build.VERSION.SDK_INT >= 26) {
                setAutoSizeTextTypeUniformWithConfiguration(18, 46, 1, TypedValue.COMPLEX_UNIT_SP)
            } else {
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 30f)
            }
        }

        pill = CounterPill(context).apply {
            this.accent = this@ReminderCard.accent
            textColor = cream
        }

        // "Touch anywhere to count", with its icon.
        tipIcon = ImageView(context).apply {
            setImageResource(R.drawable.ic_touch_app)
        }
        tipText = TextView(context).apply {
            text = ReminderStore.tip(context)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
        }
        tipRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            addView(tipIcon, LinearLayout.LayoutParams(dp(28), dp(28)).apply { marginEnd = dp(8) })
            addView(tipText)
        }

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(22), dp(14), dp(22), dp(18))
            addView(header)
            // Takes all the height the card has left, so the dhikr sits in the
            // middle of a big, easy-to-hit target.
            addView(
                dhikrView,
                LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
                    .apply { topMargin = dp(8); bottomMargin = dp(12) },
            )
            addView(
                pill,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { gravity = Gravity.CENTER_HORIZONTAL },
            )
            addView(
                tipRow,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { gravity = Gravity.CENTER_HORIZONTAL; topMargin = dp(14) },
            )
        }

        confetti = ConfettiView(context)
        background = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, NORMAL_COLORS.copyOf()).apply {
            cornerRadius = dp(32).toFloat()
        }
        view = FrameLayout(context).apply {
            this.background = this@ReminderCard.background
            addView(
                content,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
            addView(
                confetti,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
            setOnClickListener { tap() }
            alpha = 0f
            scaleX = 0.92f
            scaleY = 0.92f
            translationY = dp(20).toFloat()
        }
        applyLook()
        render(animate = false)
        renderDay()
    }

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            context.resources.displayMetrics,
        ).toInt()

    /** Fades and floats the card in. */
    fun animateIn() {
        view.animate()
            .alpha(1f).scaleX(1f).scaleY(1f).translationY(0f)
            .setDuration(300)
            .setInterpolator(DecelerateInterpolator(1.6f))
            .start()
    }

    /** Fades the card out, then calls [onEnd]. */
    fun animateOut(onEnd: () -> Unit) {
        view.animate().alpha(0f).scaleX(0.92f).scaleY(0.92f).setDuration(220)
            .withEndAction(onEnd)
            .start()
    }

    /** Stops everything the card still has scheduled. Call when it is taken away. */
    fun release() {
        released = true
        handler.removeCallbacksAndMessages(null)
    }

    /** Paints everything that depends on [doneFraction], [glowFlash] and [strokeBoost]. */
    private fun applyLook() {
        val colors = IntArray(NORMAL_COLORS.size) {
            evaluator.evaluate(doneFraction, NORMAL_COLORS[it], DONE_COLORS[it]) as Int
        }
        background.colors = colors
        accent = evaluator.evaluate(doneFraction, NORMAL_ACCENT, DONE_ACCENT) as Int
        background.setStroke(dp(2) + (dp(3) * strokeBoost).toInt(), accent)

        titleView.setTextColor(accent)
        closeView.setTextColor(accent)
        pill.accent = accent
        pill.textColor = if (doneFraction > 0.5f) accent else Color.parseColor("#F6E7C8")

        val hint = Color.argb(128, Color.red(accent), Color.green(accent), Color.blue(accent))
        tipText.setTextColor(hint)
        tipIcon.setColorFilter(hint, PorterDuff.Mode.SRC_IN)

        // The golden glow around the dhikr; it flashes outward on every tap.
        val glowBase = evaluator.evaluate(doneFraction, NORMAL_GLOW, DONE_ACCENT) as Int
        val glowAlpha = (255 * (0.85f + 0.15f * glowFlash)).toInt()
        dhikrView.setShadowLayer(
            (dp(10) + dp(14) * glowFlash),
            0f,
            0f,
            Color.argb(glowAlpha, Color.red(glowBase), Color.green(glowBase), Color.blue(glowBase)),
        )
    }

    private fun animateLook(duration: Long, interpolator: TimeInterpolator, update: (Float) -> Unit) {
        ValueAnimator.ofFloat(0f, 1f).apply {
            this.duration = duration
            this.interpolator = interpolator
            addUpdateListener {
                if (released) return@addUpdateListener
                update(it.animatedValue as Float)
                applyLook()
            }
            start()
        }
    }

    private fun tap() {
        if (count >= amount || released) return
        count++
        ReminderStore.addTap(context, dhikrId)
        if (goal > 0) {
            dayCount++
            renderDay()
        }
        listener.onTap(count)
        view.performHapticFeedback(HapticFeedback_TAP)
        render(animate = true)

        // The counter squashes and settles; the glow and the frame flash.
        pill.animate().scaleX(0.7f).scaleY(0.7f).setDuration(90)
            .setInterpolator(DecelerateInterpolator())
            .withEndAction {
                pill.animate().scaleX(1f).scaleY(1f).setDuration(320)
                    .setInterpolator(OvershootInterpolator(3f)).start()
            }.start()
        animateLook(500, LinearInterpolator()) { t ->
            val pulse = if (t < 0.35f) t / 0.35f else 1f - (t - 0.35f) / 0.65f
            glowFlash = pulse
            strokeBoost = pulse
        }

        if (count >= amount) finish()
    }

    /** The target is reached: ease to green, burst confetti, then ask to be taken away. */
    private fun finish() {
        listener.onFinished()
        animateLook(1500, PathInterpolator(0.33f, 1f, 0.68f, 1f)) { t -> doneFraction = t }
        tipRow.animate().alpha(0f).setDuration(300).start()
        confetti.fire()
        handler.postDelayed({ if (!released) listener.onDone() }, DONE_DWELL_MS)
    }

    private fun renderDay() {
        if (goal > 0) dayNumber.text = "$dayCount / $goal"
    }

    private fun render(animate: Boolean) {
        val done = count >= amount
        pill.show(
            if (done) "✓" else "$count / $amount",
            count.toFloat() / amount,
            animate,
        )
    }

    private companion object {
        // Long enough for the confetti burst to play out.
        const val DONE_DWELL_MS = 2200L
        const val HapticFeedback_TAP = HapticFeedbackConstants.VIRTUAL_KEY

        val NORMAL_ACCENT = Color.parseColor("#E7AA48")
        val DONE_ACCENT = Color.parseColor("#34D399")
        val NORMAL_GLOW = Color.parseColor("#E8B058")

        // The same gold gradient as the desktop card, a little darker and 90%
        // opaque so what is behind it does not distract.
        val NORMAL_COLORS = intArrayOf(
            Color.argb(0xE6, 118, 85, 38),
            Color.argb(0xE6, 156, 115, 49),
            Color.argb(0xE6, 123, 82, 33),
            Color.argb(0xE6, 86, 57, 25),
            Color.argb(0xE6, 45, 31, 15),
        )
        val DONE_COLORS = intArrayOf(
            Color.argb(0xD9, 40, 170, 124),
            Color.argb(0xD9, 36, 161, 109),
            Color.argb(0xD9, 31, 151, 96),
            Color.argb(0xD9, 25, 142, 79),
            Color.argb(0xD9, 18, 134, 61),
        )
    }
}
