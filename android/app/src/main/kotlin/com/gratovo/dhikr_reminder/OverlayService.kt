package com.gratovo.dhikr_reminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Shows one dhikr as a floating card over whatever app is in front -- the
 * phone's version of the Windows reminder popup. Tap the card to count, the
 * cross to dismiss it. Touches outside the card go through to the app behind.
 *
 * A foreground service only for as long as the card is up, because a plain
 * background service would be killed within about a minute.
 */
class OverlayService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var card: View? = null

    private var dhikrId = 0
    private var amount = 1
    private var count = 0

    private lateinit var counterView: TextView
    private lateinit var tipView: TextView

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForeground()
        val reminder = intent?.getIntExtra(ReminderAlarms.EXTRA_ID, -1)
            ?.let { ReminderStore.find(this, it) }
        // Never interrupts a card that is still being counted.
        if (reminder == null || card != null) {
            if (card == null) stopSelf()
            return START_NOT_STICKY
        }
        show(reminder)
        return START_NOT_STICKY
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

        val accent = Color.parseColor("#E7AA48")
        val cream = Color.parseColor("#F6E7C8")
        val arabic = try {
            Typeface.createFromAsset(assets, "flutter_assets/assets/fonts/ali-meshref.ttf")
        } catch (e: Exception) {
            Typeface.DEFAULT
        }

        val title = TextView(this).apply {
            text = ReminderStore.title(this@OverlayService)
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        }
        val close = TextView(this).apply {
            text = "✕"
            contentDescription = ReminderStore.closeLabel(this@OverlayService)
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setPadding(dp(12), dp(4), dp(4), dp(4))
            setOnClickListener { dismiss() }
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(title, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            addView(close)
        }
        val text = TextView(this).apply {
            this.text = reminder.text
            typeface = arabic
            setTextColor(cream)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 30f)
            gravity = Gravity.CENTER
            textDirection = View.TEXT_DIRECTION_RTL
            setLineSpacing(0f, 1.45f)
        }
        counterView = TextView(this).apply {
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 24f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        tipView = TextView(this).apply {
            setTextColor(cream)
            alpha = 0.7f
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
        }

        val body = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(14), dp(20), dp(16))
            background = cardBackground(done = false)
            addView(header)
            addView(
                text,
                // Takes all the height the card has left, so the dhikr sits in
                // the middle of a big, easy-to-hit target.
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    0,
                    1f,
                ).apply { topMargin = dp(12); bottomMargin = dp(14) },
            )
            addView(counterView)
            addView(tipView)
            setOnClickListener { tap() }
            alpha = 0f
            scaleX = 0.92f
            scaleY = 0.92f
        }
        card = body
        render()

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
        body.animate().alpha(1f).scaleX(1f).scaleY(1f).setDuration(220).start()
        // A card nobody touches does not stay up forever.
        handler.postDelayed({ dismiss() }, IDLE_TIMEOUT_MS)
    }

    private fun cardBackground(done: Boolean): GradientDrawable {
        val colors = if (done) {
            intArrayOf(0xCC34D399.toInt(), 0xE016A34A.toInt())
        } else {
            intArrayOf(
                0xE090682F.toInt(),
                0xE0BE8C3C.toInt(),
                0xE0966428.toInt(),
                0xE069461E.toInt(),
                0xE0372612.toInt(),
            )
        }
        return GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, colors).apply {
            cornerRadius = dp(28).toFloat()
            setStroke(dp(2), if (done) Color.parseColor("#34D399") else Color.parseColor("#E7AA48"))
        }
    }

    private fun tap() {
        if (count >= amount) return
        count++
        ReminderStore.addTap(this, dhikrId)
        card?.performHapticFeedback(HapticFeedback_TAP)
        render()
        if (count >= amount) {
            card?.background = cardBackground(done = true)
            handler.postDelayed({ dismiss() }, DONE_DWELL_MS)
        }
    }

    private fun render() {
        counterView.text = if (count >= amount) "✓" else "$count / $amount"
        tipView.text = if (count >= amount) "" else tipText()
    }

    private fun tipText(): String = ReminderStore.tip(this)

    private fun dismiss() {
        handler.removeCallbacksAndMessages(null)
        val view = card
        if (view == null) {
            stopSelf()
            return
        }
        view.animate().alpha(0f).scaleX(0.92f).scaleY(0.92f).setDuration(180)
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
        private const val DONE_DWELL_MS = 1600L
        private const val HapticFeedback_TAP = HapticFeedbackConstants.VIRTUAL_KEY

        fun intent(context: Context, reminderId: Int): Intent =
            Intent(context, OverlayService::class.java).putExtra(ReminderAlarms.EXTRA_ID, reminderId)
    }
}
