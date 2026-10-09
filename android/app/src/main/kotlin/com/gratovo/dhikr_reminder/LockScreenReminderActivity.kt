package com.gratovo.dhikr_reminder

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout

/**
 * The reminder card on the lock screen.
 *
 * A window drawn over other apps cannot sit above the lock screen, so when a
 * reminder is due while the phone is locked this activity is started instead:
 * it is allowed to show over the keyguard and to turn the screen on, and it
 * holds the screen on for [PendingRules.LOCKSCREEN_MILLIS]. When that time is
 * up (or the person touches outside the card, presses the power or home
 * button, or unlocks) it finishes, which lets the screen go back to sleep.
 *
 * Finishing is not the end of the reminder. It stays waiting in
 * [ReminderStore] and comes back as the usual card over other apps at the next
 * unlock (see [OverlayService]), until the dhikr is counted through or the
 * card is closed with its cross.
 */
class LockScreenReminderActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { finish() }
    private var card: ReminderCard? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        // Held for as long as this activity lives, and not a moment longer.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val pending = ReminderStore.pending(this, System.currentTimeMillis())
        if (pending == null) {
            finish()
            return
        }
        ReminderStore.setLockScreenShown(this, System.currentTimeMillis())

        val shown = ReminderCard(this, pending.reminder, pending.count, CardListener())
        card = shown
        val host = CardHost(this).apply {
            setBackgroundColor(Color.argb(0x99, 0, 0, 0))
            addView(shown.view)
            // A touch beside the card goes back to the lock screen, so the
            // phone can still be unlocked.
            setOnClickListener { finish() }
        }
        setContentView(host)
        shown.animateIn()

        current = this
        restartTimer()
    }

    private fun restartTimer() {
        handler.removeCallbacks(timeout)
        handler.postDelayed(timeout, PendingRules.LOCKSCREEN_MILLIS)
    }

    /** Anything that takes the card off the screen (power, home, an unlock) ends it. */
    override fun onStop() {
        super.onStop()
        if (!isFinishing) finish()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        card?.release()
        if (current === this) current = null
        super.onDestroy()
    }

    private inner class CardListener : ReminderCard.Listener {
        override fun onTap(count: Int) {
            ReminderStore.updatePendingCount(this@LockScreenReminderActivity, count)
            // Someone counting is not someone who has finished with the screen.
            restartTimer()
        }

        override fun onFinished() {
            Chime.playIfEnabled(this@LockScreenReminderActivity)
            Surfaces.refresh(this@LockScreenReminderActivity)
            handler.removeCallbacks(timeout)
            ReminderStore.clearPending(this@LockScreenReminderActivity)
            OverlayService.pendingChanged()
        }

        override fun onClose() {
            Surfaces.refresh(this@LockScreenReminderActivity)
            ReminderStore.clearPending(this@LockScreenReminderActivity)
            OverlayService.pendingChanged()
            finish()
        }

        override fun onDone() {
            finish()
        }
    }

    /** Lays its one child out at 90% of the screen in each direction, centred, whatever the rotation. */
    private class CardHost(context: Context) : FrameLayout(context) {
        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            val width = MeasureSpec.getSize(widthMeasureSpec)
            val height = MeasureSpec.getSize(heightMeasureSpec)
            setMeasuredDimension(width, height)
            val child = getChildAt(0) ?: return
            child.measure(
                MeasureSpec.makeMeasureSpec((width * CARD_FRACTION).toInt(), MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec((height * CARD_FRACTION).toInt(), MeasureSpec.EXACTLY),
            )
        }

        override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
            val child: View = getChildAt(0) ?: return
            val x = (right - left - child.measuredWidth) / 2
            val y = (bottom - top - child.measuredHeight) / 2
            child.layout(x, y, x + child.measuredWidth, y + child.measuredHeight)
        }
    }

    companion object {
        private const val CARD_FRACTION = 0.9f

        /** The one showing now, so the rest of the app can tell and can close it. */
        @Volatile
        var current: LockScreenReminderActivity? = null
            private set

        /** Whether the card is on the lock screen right now. */
        val isShowing: Boolean get() = current != null

        /** Takes the card off the lock screen, if it is there. */
        fun close() {
            current?.runOnUiThread { current?.finish() }
        }
    }
}
