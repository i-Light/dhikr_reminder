package com.gratovo.dhikr_reminder

import android.animation.ArgbEvaluator
import android.animation.TimeInterpolator
import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import android.view.animation.OvershootInterpolator
import android.view.animation.PathInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Shows one dhikr as a floating card over whatever app is in front -- the
 * phone's version of the Windows reminder popup, with the same look: the app
 * icon and title, the dhikr in Ali Meshref with a golden glow, a counter whose
 * frame fills as you count, a "touch anywhere to count" hint, and a green
 * confetti finish. Tap the card to count, the cross to dismiss it. Touches
 * outside the card go through to the app behind.
 *
 * A foreground service only for as long as the card is up, because a plain
 * background service would be killed within about a minute.
 */
class OverlayService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val evaluator = ArgbEvaluator()
    private var windowManager: WindowManager? = null
    private var card: View? = null

    private var dhikrId = 0
    private var amount = 1
    private var count = 0

    private lateinit var background: GradientDrawable
    private lateinit var titleView: TextView
    private lateinit var closeView: TextView
    private lateinit var dhikrView: TextView
    private lateinit var pill: CounterPill
    private lateinit var tipRow: View
    private lateinit var tipIcon: ImageView
    private lateinit var tipText: TextView
    private lateinit var confetti: ConfettiView

    private var accent = NORMAL_ACCENT
    private var doneFraction = 0f
    private var glowFlash = 0f
    private var strokeBoost = 0f

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForeground()
        val reminder = reminderFrom(intent)
        // Never interrupts a card that is still being counted.
        if (reminder == null || card != null) {
            if (card == null) stopSelf()
            return START_NOT_STICKY
        }
        show(reminder)
        return START_NOT_STICKY
    }

    /** A planned reminder named by its id, or one carried whole by the intent. */
    private fun reminderFrom(intent: Intent?): ReminderStore.Planned? {
        intent ?: return null
        val text = intent.getStringExtra(EXTRA_TEXT)
        if (text != null) {
            return ReminderStore.Planned(
                -1,
                0L,
                intent.getIntExtra(EXTRA_DHIKR_ID, 0),
                text,
                intent.getIntExtra(EXTRA_AMOUNT, 1),
            )
        }
        return ReminderStore.find(this, intent.getIntExtra(ReminderAlarms.EXTRA_ID, -1))
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        removeCard()
        super.onDestroy()
    }

    // ---- foreground notification --------------------------------------

    private fun startAsForeground() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Reminder window", NotificationManager.IMPORTANCE_MIN),
        )
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(ReminderStore.title(this))
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    // ---- the card -----------------------------------------------------

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()

    private fun show(reminder: ReminderStore.Planned) {
        dhikrId = reminder.dhikrId
        amount = reminder.amount.coerceAtLeast(1)
        count = 0
        accent = NORMAL_ACCENT
        doneFraction = 0f
        glowFlash = 0f
        strokeBoost = 0f

        val cream = Color.parseColor("#F6E7C8")
        val arabic = try {
            Typeface.createFromAsset(assets, "flutter_assets/assets/fonts/ali-meshref.ttf")
        } catch (e: Exception) {
            Typeface.DEFAULT
        }

        // Header: the app icon, the title, the cross.
        val logo = ImageView(this).apply {
            setImageResource(R.mipmap.ic_launcher_foreground)
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        titleView = TextView(this).apply {
            text = ReminderStore.title(this@OverlayService)
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }
        closeView = TextView(this).apply {
            text = "✕"
            contentDescription = ReminderStore.closeLabel(this@OverlayService)
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setPadding(dp(12), dp(4), dp(4), dp(4))
            setOnClickListener { dismiss() }
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(logo, LinearLayout.LayoutParams(dp(44), dp(44)).apply {
                marginEnd = dp(4)
            })
            addView(titleView, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            addView(closeView)
        }

        // The dhikr, as large as fits.
        dhikrView = TextView(this).apply {
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

        pill = CounterPill(this).apply {
            this.accent = this@OverlayService.accent
            textColor = cream
        }

        // "Touch anywhere to count", with its icon.
        tipIcon = ImageView(this).apply {
            setImageResource(R.drawable.ic_touch_app)
        }
        tipText = TextView(this).apply {
            text = ReminderStore.tip(this@OverlayService)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
        }
        tipRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            addView(tipIcon, LinearLayout.LayoutParams(dp(28), dp(28)).apply { marginEnd = dp(8) })
            addView(tipText)
        }

        val content = LinearLayout(this).apply {
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

        confetti = ConfettiView(this)
        background = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, NORMAL_COLORS.copyOf()).apply {
            cornerRadius = dp(32).toFloat()
        }
        val body = FrameLayout(this).apply {
            this.background = this@OverlayService.background
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
        card = body
        applyLook()
        render(animate = false)

        // 80% of the screen's width and 90% of its height: big enough to
        // reach from anywhere with one thumb.
        val metrics = resources.displayMetrics
        val params = WindowManager.LayoutParams(
            (metrics.widthPixels * CARD_WIDTH_FRACTION).toInt(),
            (metrics.heightPixels * CARD_HEIGHT_FRACTION).toInt(),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.CENTER }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            windowManager?.addView(body, params)
        } catch (e: Exception) {
            // The permission was withdrawn in the meantime.
            card = null
            stopSelf()
            return
        }
        body.animate()
            .alpha(1f).scaleX(1f).scaleY(1f).translationY(0f)
            .setDuration(300)
            .setInterpolator(DecelerateInterpolator(1.6f))
            .start()
        // A card nobody touches does not stay up forever.
        handler.postDelayed({ dismiss() }, IDLE_TIMEOUT_MS)
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
                if (card == null) return@addUpdateListener
                update(it.animatedValue as Float)
                applyLook()
            }
            start()
        }
    }

    private fun tap() {
        if (count >= amount) return
        count++
        ReminderStore.addTap(this, dhikrId)
        card?.performHapticFeedback(HapticFeedback_TAP)
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

    /** The target is reached: ease to green, burst confetti, then go away. */
    private fun finish() {
        animateLook(1500, PathInterpolator(0.33f, 1f, 0.68f, 1f)) { t -> doneFraction = t }
        tipRow.animate().alpha(0f).setDuration(300).start()
        confetti.fire()
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({ dismiss() }, DONE_DWELL_MS)
    }

    private fun render(animate: Boolean) {
        val done = count >= amount
        pill.show(
            if (done) "✓" else "$count / $amount",
            count.toFloat() / amount,
            animate,
        )
    }

    private fun dismiss() {
        handler.removeCallbacksAndMessages(null)
        val view = card
        if (view == null) {
            stopSelf()
            return
        }
        view.animate().alpha(0f).scaleX(0.92f).scaleY(0.92f).setDuration(220)
            .withEndAction {
                removeCard()
                stopSelf()
            }
            .start()
    }

    private fun removeCard() {
        val view = card ?: return
        card = null
        try {
            windowManager?.removeView(view)
        } catch (e: Exception) {
            // Already gone.
        }
    }

    companion object {
        private const val CHANNEL_ID = "dhikr_overlay"
        private const val NOTIFICATION_ID = 4711
        private const val CARD_WIDTH_FRACTION = 0.8f
        private const val CARD_HEIGHT_FRACTION = 0.9f
        private const val IDLE_TIMEOUT_MS = 3 * 60 * 1000L

        // Long enough for the confetti burst to play out.
        private const val DONE_DWELL_MS = 2200L
        private const val HapticFeedback_TAP = HapticFeedbackConstants.VIRTUAL_KEY

        private val NORMAL_ACCENT = Color.parseColor("#E7AA48")
        private val DONE_ACCENT = Color.parseColor("#34D399")
        private val NORMAL_GLOW = Color.parseColor("#E8B058")

        // The same gold gradient as the desktop card, a little darker and 90%
        // opaque so what is behind it does not distract.
        private val NORMAL_COLORS = intArrayOf(
            Color.argb(0xE6, 118, 85, 38),
            Color.argb(0xE6, 156, 115, 49),
            Color.argb(0xE6, 123, 82, 33),
            Color.argb(0xE6, 86, 57, 25),
            Color.argb(0xE6, 45, 31, 15),
        )
        private val DONE_COLORS = intArrayOf(
            Color.argb(0xD9, 40, 170, 124),
            Color.argb(0xD9, 36, 161, 109),
            Color.argb(0xD9, 31, 151, 96),
            Color.argb(0xD9, 25, 142, 79),
            Color.argb(0xD9, 18, 134, 61),
        )

        private const val EXTRA_TEXT = "reminder_text"
        private const val EXTRA_DHIKR_ID = "reminder_dhikr_id"
        private const val EXTRA_AMOUNT = "reminder_amount"

        /** A reminder to show right now, not one from the plan. */
        fun intentNow(context: Context, dhikrId: Int, text: String, amount: Int): Intent =
            Intent(context, OverlayService::class.java)
                .putExtra(EXTRA_TEXT, text)
                .putExtra(EXTRA_DHIKR_ID, dhikrId)
                .putExtra(EXTRA_AMOUNT, amount)

        fun intent(context: Context, reminderId: Int): Intent =
            Intent(context, OverlayService::class.java).putExtra(ReminderAlarms.EXTRA_ID, reminderId)
    }
}
