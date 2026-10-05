package com.gratovo.dhikr_reminder

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PathMeasure
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.util.TypedValue
import android.view.View
import android.view.animation.DecelerateInterpolator
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.random.Random

private fun View.dp(value: Float): Float =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

private fun View.sp(value: Float): Float =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value, resources.displayMetrics)

/**
 * The count ("3 / 33") in a rounded frame whose edge fills clockwise as the
 * count climbs, like the progress frame on the desktop card. A new count rolls
 * in from below while the old one fades away, and the fill eases to its new
 * length.
 */
class CounterPill(context: Context) : View(context) {
    var accent: Int = Color.WHITE
        set(value) {
            field = value
            rebuildFill()
            invalidate()
        }

    var textColor: Int = Color.WHITE
        set(value) {
            field = value
            invalidate()
        }

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        typeface = Typeface.DEFAULT_BOLD
        textSize = sp(20f)
        textAlign = Paint.Align.CENTER
    }
    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = dp(3f)
    }
    private val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = dp(3f)
        strokeCap = Paint.Cap.ROUND
    }
    private val rect = RectF()
    private val arc = RectF()
    private val path = Path()
    private val segment = Path()

    private var text = ""
    private var previous = ""
    private var shift = 1f
    private var progress = 0f
    private var shiftAnimator: ValueAnimator? = null
    private var progressAnimator: ValueAnimator? = null

    /** Shows [newText] with the frame filled to [target] (0..1). */
    fun show(newText: String, target: Float, animate: Boolean) {
        if (newText != text) {
            previous = text
            text = newText
            requestLayout()
            shiftAnimator?.cancel()
            if (animate && previous.isNotEmpty()) {
                shift = 0f
                shiftAnimator = ValueAnimator.ofFloat(0f, 1f).apply {
                    duration = 320
                    addUpdateListener {
                        shift = it.animatedValue as Float
                        invalidate()
                    }
                    start()
                }
            } else {
                shift = 1f
            }
        }
        progressAnimator?.cancel()
        if (animate) {
            progressAnimator = ValueAnimator.ofFloat(progress, target).apply {
                duration = 300
                interpolator = DecelerateInterpolator(2f)
                addUpdateListener {
                    progress = it.animatedValue as Float
                    invalidate()
                }
                start()
            }
        } else {
            progress = target
        }
        invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val widest = max(textPaint.measureText(text), textPaint.measureText(previous))
        val width = max(dp(104f), widest + dp(48f)).toInt()
        setMeasuredDimension(
            resolveSize(width, widthMeasureSpec),
            resolveSize(dp(46f).toInt(), heightMeasureSpec),
        )
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        rebuildFill()
    }

    private fun rebuildFill() {
        if (height <= 0) return
        // Gold at the bottom fading to nothing at the top.
        val strong = Color.argb(150, Color.red(accent), Color.green(accent), Color.blue(accent))
        val clear = Color.argb(0, Color.red(accent), Color.green(accent), Color.blue(accent))
        fillPaint.shader = LinearGradient(
            0f, height.toFloat(), 0f, 0f, strong, clear, Shader.TileMode.CLAMP,
        )
    }

    override fun onDraw(canvas: Canvas) {
        val inset = trackPaint.strokeWidth / 2f
        rect.set(inset, inset, width - inset, height - inset)
        val r = min(dp(20f), rect.height() / 2f)
        canvas.drawRoundRect(rect, r, r, fillPaint)

        // Starts at the top centre and runs clockwise, as on the desktop card.
        path.rewind()
        path.moveTo(rect.centerX(), rect.top)
        path.lineTo(rect.right - r, rect.top)
        arc.set(rect.right - 2 * r, rect.top, rect.right, rect.top + 2 * r)
        path.arcTo(arc, 270f, 90f)
        path.lineTo(rect.right, rect.bottom - r)
        arc.set(rect.right - 2 * r, rect.bottom - 2 * r, rect.right, rect.bottom)
        path.arcTo(arc, 0f, 90f)
        path.lineTo(rect.left + r, rect.bottom)
        arc.set(rect.left, rect.bottom - 2 * r, rect.left + 2 * r, rect.bottom)
        path.arcTo(arc, 90f, 90f)
        path.lineTo(rect.left, rect.top + r)
        arc.set(rect.left, rect.top, rect.left + 2 * r, rect.top + 2 * r)
        path.arcTo(arc, 180f, 90f)
        path.close()

        trackPaint.color = Color.argb(77, Color.red(accent), Color.green(accent), Color.blue(accent))
        canvas.drawPath(path, trackPaint)
        if (progress > 0f) {
            progressPaint.color = accent
            val measure = PathMeasure(path, false)
            segment.rewind()
            measure.getSegment(0f, measure.length * progress.coerceIn(0f, 1f), segment, true)
            canvas.drawPath(segment, progressPaint)
        }

        val baseline = height / 2f - (textPaint.ascent() + textPaint.descent()) / 2f
        val slide = textPaint.textSize * 0.4f
        textPaint.color = textColor
        if (shift < 1f && previous.isNotEmpty()) {
            textPaint.alpha = ((1f - shift) * 255).toInt()
            canvas.drawText(previous, width / 2f, baseline + shift * slide, textPaint)
        }
        textPaint.color = textColor
        textPaint.alpha = (shift * 255).toInt()
        canvas.drawText(text, width / 2f, baseline + (1f - shift) * slide, textPaint)
    }
}

/**
 * A short burst of confetti from the middle of the card when the target is
 * reached: the flakes fly out, fall and fade, like the desktop card's.
 */
class ConfettiView(context: Context) : View(context) {
    private class Flake(
        val angle: Float,
        val distance: Float,
        val size: Float,
        val color: Int,
        val spin: Float,
        val delay: Float,
    )

    private val colors = intArrayOf(
        Color.parseColor("#2ECC71"),
        Color.parseColor("#F1C40F"),
        Color.parseColor("#E74C3C"),
        Color.parseColor("#3498DB"),
        Color.parseColor("#E67E22"),
        Color.parseColor("#9B59B6"),
    )
    private var flakes = emptyList<Flake>()
    private var progress = 0f
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    init {
        // Never takes a tap from the card underneath.
        isClickable = false
        isFocusable = false
    }

    fun fire() {
        flakes = List(24) {
            Flake(
                angle = Random.nextFloat() * 2f * Math.PI.toFloat(),
                distance = 60f + Random.nextFloat() * 50f,
                size = 4f + Random.nextFloat() * 4f,
                color = colors[Random.nextInt(colors.size)],
                spin = (Random.nextFloat() - 0.5f) * 10f,
                delay = Random.nextFloat() * 0.25f,
            )
        }
        ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 2000
            addUpdateListener {
                progress = it.animatedValue as Float
                invalidate()
            }
            start()
        }
    }

    override fun onDraw(canvas: Canvas) {
        if (progress <= 0f) return
        val density = resources.displayMetrics.density
        val scale = density * 1.6f
        val cx = width / 2f
        val cy = height * 0.4f
        for (flake in flakes) {
            val t = ((progress - flake.delay) / (1f - flake.delay)).coerceIn(0f, 1f)
            if (t <= 0f) continue
            val eased = 1f - (1f - t) * (1f - t)
            val dx = cos(flake.angle) * flake.distance * scale * eased
            val dy = sin(flake.angle) * flake.distance * scale * eased * 0.6f +
                130f * scale * eased * eased
            paint.color = flake.color
            paint.alpha = ((1f - t) * 255).toInt()
            canvas.save()
            canvas.translate(cx + dx, cy + dy)
            canvas.rotate(flake.spin * progress * 180f)
            val w = flake.size * density
            canvas.drawRect(-w / 2f, -w * 0.8f, w / 2f, w * 0.8f, paint)
            canvas.restore()
        }
    }
}
