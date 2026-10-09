package com.gratovo.dhikr_reminder

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.view.Gravity
import android.view.WindowManager

/**
 * Shows the reminder card, and sees to it that a reminder nobody counted is
 * not forgotten.
 *
 * Three jobs:
 *
 *  1. A reminder due while the phone is in use: the card floats over whatever
 *     app is in front ([intentNow]). Touches outside the card go through to the
 *     app behind. Left alone for three minutes it goes away.
 *
 *  2. A reminder due while the phone is locked ([intentLocked]): it is saved as
 *     the pending reminder (see [ReminderStore.setPending]), the screen is lit
 *     with the card on the lock screen for 30 seconds
 *     ([LockScreenReminderActivity]), and then the phone is let go back to
 *     sleep. A window over other apps cannot be drawn above the lock screen,
 *     which is why that card is an activity.
 *
 *  3. Waiting for the next unlock. While a reminder is pending this service
 *     stays alive and listens for the phone being unlocked; when it is, the
 *     card appears over whatever app is in front, again and again, until the
 *     dhikr is counted through or the card is closed with its cross. Locking
 *     the phone, or leaving the card for three minutes, only takes the card off
 *     the screen; the reminder keeps waiting, and keeps how far it got.
 *
 * A foreground service for as long as there is a card or a reminder waiting,
 * because a plain background service would be killed within about a minute.
 */
class OverlayService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var card: ReminderCard? = null

    /** Whether the card on screen is the pending reminder, not a one-off. */
    private var cardIsPending = false

    private var listening = false
    private var wakeLock: PowerManager.WakeLock? = null

    private val idleTimeout = Runnable {
        removeCard()
        stopIfIdle()
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_USER_PRESENT -> unlocked()
                // A phone with no lock screen at all sends this and nothing else.
                Intent.ACTION_SCREEN_ON -> if (!keyguardLocked()) unlocked()
                Intent.ACTION_SCREEN_OFF -> screenOff()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        current = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForeground()
        when {
            // Restarted by the system after it killed this process.
            intent == null -> resumeWaiting()
            intent.action == ACTION_LOCKED -> reminderWhileLocked()
            intent.action == ACTION_WATCH -> resumeWaiting()
            else -> reminderNow(intent)
        }
        return if (listening) START_STICKY else START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        stopListening()
        removeCard()
        releaseWake()
        if (current === this) current = null
        super.onDestroy()
    }

    // ---- what a start command asks for --------------------------------

    /** A reminder to show right now, not one from the plan. */
    private fun reminderNow(intent: Intent) {
        val reminder = reminderFrom(intent)
        // Never interrupts a card that is still being counted.
        if (reminder == null || card != null) {
            stopIfIdle()
            return
        }
        showCard(reminder, startCount = 0, pending = false)
    }

    /** The reminder just saved as pending arrived while the phone was locked. */
    private fun reminderWhileLocked() {
        val pending = ReminderStore.pending(this, System.currentTimeMillis())
        if (pending == null) {
            stopIfIdle()
            return
        }
        listen()
        // A card left from before the screen went off is no use to anyone.
        removeCard()
        holdAwake()
        launchLockScreen(pending.reminder)
    }

    /** Make sure a waiting reminder is being waited for, and show it if the phone is in use. */
    private fun resumeWaiting() {
        if (ReminderStore.pending(this, System.currentTimeMillis()) == null) {
            stopIfIdle()
            return
        }
        listen()
        if (!keyguardLocked() && (getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive) {
            showPending()
        }
    }

    // ---- the lock screen ------------------------------------------------

    private fun launchLockScreen(reminder: ReminderStore.Planned) {
        val requestedAt = System.currentTimeMillis()
        ReminderStore.setLockScreenRequested(this, requestedAt)
        try {
            startActivity(
                Intent(this, LockScreenReminderActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION),
            )
        } catch (e: Exception) {
            ReminderNotifier.post(this, reminder)
            return
        }
        // Some phones refuse to start an activity from the background and say
        // nothing. If the card has not come up shortly, the reminder arrives as
        // a notification instead; it stays pending for the next unlock either way.
        handler.postDelayed({
            if (!ReminderStore.lockScreenStarted(this)) ReminderNotifier.post(this, reminder)
        }, PendingRules.LAUNCH_CHECK_MILLIS)
    }

    // ---- waiting for the next unlock ------------------------------------

    private fun listen() {
        if (listening) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, filter)
        }
        listening = true
    }

    private fun stopListening() {
        if (!listening) return
        listening = false
        try {
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
            // Already gone.
        }
    }

    private fun keyguardLocked(): Boolean =
        (getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked

    private fun unlocked() {
        // The lock-screen card has done its job; the usual card takes over.
        LockScreenReminderActivity.close()
        showPending()
    }

    private fun screenOff() {
        LockScreenReminderActivity.close()
        // A card on a screen that is off helps nobody. A pending reminder is
        // kept for the next unlock; a one-off is let go, as it always was.
        removeCard()
        stopIfIdle()
    }

    /** The pending reminder changed or was finished elsewhere (on the lock screen). */
    fun onPendingChanged() {
        stopIfIdle()
    }

    private fun showPending() {
        val pending = ReminderStore.pending(this, System.currentTimeMillis())
        if (pending == null) {
            stopIfIdle()
            return
        }
        if (card != null) return
        showCard(pending.reminder, pending.count, pending = true)
    }

    private fun stopIfIdle() {
        if (card != null || LockScreenReminderActivity.isShowing) return
        if (ReminderStore.pending(this, System.currentTimeMillis()) != null) return
        stopListening()
        stopSelf()
    }

    // ---- the card in its window ----------------------------------------

    private fun showCard(reminder: ReminderStore.Planned, startCount: Int, pending: Boolean) {
        val shown = ReminderCard(this, reminder, startCount, CardListener())

        // 90% of the screen's width and height: big enough to reach from
        // anywhere with one thumb.
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

        val manager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            manager.addView(shown.view, params)
        } catch (e: Exception) {
            // The permission was withdrawn in the meantime.
            shown.release()
            stopIfIdle()
            return
        }
        windowManager = manager
        card = shown
        cardIsPending = pending
        busy = true
        shown.animateIn()
        // A card nobody touches does not stay up forever. A pending reminder
        // only comes off the screen, and comes back at the next unlock.
        handler.removeCallbacks(idleTimeout)
        handler.postDelayed(idleTimeout, IDLE_TIMEOUT_MS)
    }

    /** Takes the card off the screen at once. */
    private fun removeCard() {
        handler.removeCallbacks(idleTimeout)
        val shown = card ?: return
        card = null
        cardIsPending = false
        busy = false
        shown.release()
        try {
            windowManager?.removeView(shown.view)
        } catch (e: Exception) {
            // Already gone.
        }
    }

    /** Fades the card out, then takes it away. */
    private fun closeCard() {
        handler.removeCallbacks(idleTimeout)
        val shown = card
        if (shown == null) {
            stopIfIdle()
            return
        }
        shown.animateOut {
            // Only if it is still this card: the screen may have gone off meanwhile.
            if (card === shown) removeCard()
            stopIfIdle()
        }
    }

    private inner class CardListener : ReminderCard.Listener {
        override fun onTap(count: Int) {
            if (cardIsPending) ReminderStore.updatePendingCount(this@OverlayService, count)
        }

        override fun onFinished() {
            Chime.playIfEnabled(this@OverlayService)
            Surfaces.refresh(this@OverlayService)
            handler.removeCallbacks(idleTimeout)
            if (cardIsPending) ReminderStore.clearPending(this@OverlayService)
        }

        override fun onClose() {
            Surfaces.refresh(this@OverlayService)
            // The cross says "not this one": that ends a waiting reminder.
            if (cardIsPending) ReminderStore.clearPending(this@OverlayService)
            closeCard()
        }

        override fun onDone() {
            closeCard()
        }
    }

    // ---- staying awake ---------------------------------------------------

    /** Keeps the CPU running while the lock-screen card is being started. */
    private fun holdAwake() {
        releaseWake()
        try {
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "dhikr_reminder:lockscreen")
                .apply { acquire(PendingRules.WAKE_HOLD_MILLIS) }
        } catch (e: Exception) {
            // Without it the activity may start a little late; nothing worse.
        }
    }

    private fun releaseWake() {
        try {
            wakeLock?.takeIf { it.isHeld }?.release()
        } catch (e: Exception) {
            // Already released.
        }
        wakeLock = null
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

    /** The reminder the intent carries whole (see [intentNow]). */
    private fun reminderFrom(intent: Intent): ReminderStore.Planned? {
        val text = intent.getStringExtra(EXTRA_TEXT) ?: return null
        return ReminderStore.Planned(
            -1,
            0L,
            intent.getIntExtra(EXTRA_DHIKR_ID, 0),
            text,
            intent.getIntExtra(EXTRA_AMOUNT, 1),
            intent.getIntExtra(EXTRA_GOAL, 0),
            intent.getStringExtra(EXTRA_TRANSLIT) ?: "",
        )
    }

    companion object {
        private const val CHANNEL_ID = "dhikr_overlay"
        private const val NOTIFICATION_ID = 4711
        private const val CARD_WIDTH_FRACTION = 0.9f
        private const val CARD_HEIGHT_FRACTION = 0.9f
        private const val IDLE_TIMEOUT_MS = 3 * 60 * 1000L

        private const val ACTION_LOCKED = "com.gratovo.dhikr_reminder.LOCKED"
        private const val ACTION_WATCH = "com.gratovo.dhikr_reminder.WATCH"

        private const val EXTRA_TEXT = "reminder_text"
        private const val EXTRA_DHIKR_ID = "reminder_dhikr_id"
        private const val EXTRA_AMOUNT = "reminder_amount"
        private const val EXTRA_GOAL = "reminder_goal"
        private const val EXTRA_TRANSLIT = "reminder_translit"

        @Volatile
        private var current: OverlayService? = null

        /** Whether a card is on screen over other apps right now. */
        @Volatile
        var busy: Boolean = false
            private set

        /** A reminder to show right now, not one from the plan. */
        fun intentNow(
            context: Context,
            dhikrId: Int,
            text: String,
            amount: Int,
            goal: Int = 0,
            translit: String = "",
        ): Intent =
            Intent(context, OverlayService::class.java)
                .putExtra(EXTRA_TEXT, text)
                .putExtra(EXTRA_DHIKR_ID, dhikrId)
                .putExtra(EXTRA_AMOUNT, amount)
                .putExtra(EXTRA_GOAL, goal)
                .putExtra(EXTRA_TRANSLIT, translit)

        /** The reminder just saved as pending arrived while the phone was locked. */
        fun intentLocked(context: Context): Intent =
            Intent(context, OverlayService::class.java).setAction(ACTION_LOCKED)

        /** Start waiting for the unlock if a reminder is pending (after a restart, say). */
        fun intentWatch(context: Context): Intent =
            Intent(context, OverlayService::class.java).setAction(ACTION_WATCH)

        /** The pending reminder was finished or closed somewhere else. */
        fun pendingChanged() {
            current?.onPendingChanged()
        }
    }
}
