package com.gratovo.dhikr_reminder

import android.content.Context
import android.graphics.Canvas
import android.graphics.Typeface
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * The dhikr on the card: the Arabic, and under it the transliteration, sized
 * together to fill the room the card leaves them.
 *
 * Two texts in one box need more than a TextView's auto-size can do, because the
 * answer for one depends on the other: the biggest Arabic that fits is the
 * biggest one that still leaves room for the transliteration under it. So this
 * searches for it. The Arabic gets the size found, the transliteration a fixed
 * share of it ([TRANSLIT_RATIO], never below [TRANSLIT_MIN_SP]), and both are
 * measured by the real TextViews, so what was measured is what is drawn.
 *
 * With the Arabic switched off the transliteration is the dhikr and is sized
 * like one. A stack that cannot fit even at the smallest size (a very long
 * dhikr with a transliteration under it) is drawn scaled down as a whole rather
 * than running out of its box.
 *
 * The Arabic font, Noto Sans Arabic, is built with room for stacked marks above
 * and below (its line is 2.1 times the text size), so a TextView's own line
 * height, or any multiple of it, spaces the lines far too wide. The Arabic gets
 * a line height of [ARABIC_LINE_EM] times its size instead, the same idea as
 * the desktop card's, and is drawn that much higher in its box to make up for
 * the empty room the font keeps above the letters.
 */
class DhikrTextStack(context: Context) : ViewGroup(context) {
    val arabicView: TextView = TextView(context).apply {
        gravity = Gravity.CENTER_HORIZONTAL
        textDirection = View.TEXT_DIRECTION_RTL
        includeFontPadding = false
    }

    val translitView: TextView = TextView(context).apply {
        gravity = Gravity.CENTER_HORIZONTAL
        textDirection = View.TEXT_DIRECTION_LTR
        includeFontPadding = false
        typeface = Typeface.create("sans-serif", Typeface.NORMAL)
    }

    private var hasArabic = true
    private var hasTranslit = false

    /** The longest words of each text, so a size is rejected if a word would be cut mid-letter. */
    private var arabicWords: List<String> = emptyList()
    private var translitWords: List<String> = emptyList()

    private var fitKey = 0
    private var fitSize = 0f
    private var drawScale = 1f
    private var arabicLift = 0

    init {
        clipChildren = false
        addView(arabicView)
        addView(translitView)
    }

    fun setTypeface(arabic: Typeface) {
        arabicView.typeface = arabic
        fitKey = 0
        requestLayout()
    }

    fun setColors(arabicColor: Int, translitColor: Int) {
        arabicView.setTextColor(arabicColor)
        translitView.setTextColor(translitColor)
    }

    /**
     * Sets the texts: [arabic] null leaves the Arabic out, [translit] null
     * leaves the transliteration out. Not both.
     */
    fun setTexts(arabic: String?, translit: String?) {
        hasArabic = arabic != null
        hasTranslit = translit != null
        arabicView.visibility = if (hasArabic) View.VISIBLE else View.GONE
        translitView.visibility = if (hasTranslit) View.VISIBLE else View.GONE
        arabicView.text = arabic ?: ""
        translitView.text = translit ?: ""
        arabicWords = words(arabic)
        translitWords = words(translit)
        fitKey = 0
        requestLayout()
    }

    private fun words(text: String?): List<String> =
        text?.split(' ', '\n', '\t')?.filter { it.isNotEmpty() } ?: emptyList()

    private fun sp(value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value, resources.displayMetrics)

    private fun dp(value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val heightMode = MeasureSpec.getMode(heightMeasureSpec)
        val heightSpec = MeasureSpec.getSize(heightMeasureSpec)
        val availW = max(0, width - paddingLeft - paddingRight)
        val availH = if (heightMode == MeasureSpec.UNSPECIFIED) Int.MAX_VALUE
        else max(0, heightSpec - paddingTop - paddingBottom)

        if (hasArabic || hasTranslit) {
            val key = listOf(availW, availH, arabicView.text.toString(), translitView.text.toString(), hasArabic)
                .hashCode()
            if (key != fitKey) {
                fitKey = key
                search(availW, availH)
            }
            apply(fitSize)
            measureTexts(availW)
        }

        val content = contentHeight()
        val height = when (heightMode) {
            MeasureSpec.EXACTLY -> heightSpec
            MeasureSpec.AT_MOST -> min(heightSpec, content + paddingTop + paddingBottom)
            else -> content + paddingTop + paddingBottom
        }
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val availW = r - l - paddingLeft - paddingRight
        val availH = b - t - paddingTop - paddingBottom
        val content = contentHeight()
        // Centred in the room it has.
        // (When it has been scaled down to fit it is drawn about the centre, so
        // the unscaled column is centred, and may start above the top.)
        var y = paddingTop + (availH - content) / 2
        if (hasArabic) {
            val top = y - arabicLift
            arabicView.layout(paddingLeft, top, paddingLeft + availW, top + arabicView.measuredHeight)
            y += arabicView.measuredHeight - arabicLift
            if (hasTranslit) y += gap()
        }
        if (hasTranslit) {
            translitView.layout(paddingLeft, y, paddingLeft + availW, y + translitView.measuredHeight)
        }
    }

    override fun dispatchDraw(canvas: Canvas) {
        if (drawScale < 1f) {
            val save = canvas.save()
            canvas.scale(drawScale, drawScale, width / 2f, height / 2f)
            super.dispatchDraw(canvas)
            canvas.restoreToCount(save)
        } else {
            super.dispatchDraw(canvas)
        }
    }

    private fun gap(): Int = dp(GAP_DP).roundToInt()

    /** Height of the two texts as laid out, with the gap between and the Arabic's lift taken off. */
    private fun contentHeight(): Int {
        var h = 0
        if (hasArabic) h += arabicView.measuredHeight - arabicLift
        if (hasTranslit) h += translitView.measuredHeight
        if (hasArabic && hasTranslit) h += gap()
        return h
    }

    private fun measureTexts(availW: Int) {
        val w = MeasureSpec.makeMeasureSpec(availW, MeasureSpec.EXACTLY)
        val h = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
        if (hasArabic) arabicView.measure(w, h)
        if (hasTranslit) translitView.measure(w, h)
    }

    /** Gives both texts the sizes that go with [base], the size of the first one shown. */
    private fun apply(base: Float) {
        if (hasArabic) {
            arabicView.setTextSize(TypedValue.COMPLEX_UNIT_PX, base)
            val metrics = arabicView.paint.fontMetrics
            val natural = metrics.descent - metrics.ascent
            arabicView.setLineSpacing(ARABIC_LINE_EM * base - natural, 1f)
            // The font keeps room above the letters for marks; take back what
            // the letters (marks included) do not use.
            arabicLift = max(0f, -metrics.ascent - ARABIC_INK_ASCENT_EM * base).roundToInt()
        }
        if (hasTranslit) {
            val size = if (hasArabic) max(sp(TRANSLIT_MIN_SP), base * TRANSLIT_RATIO) else base
            translitView.setTextSize(TypedValue.COMPLEX_UNIT_PX, size)
            translitView.setLineSpacing(0f, if (hasArabic) 1.25f else 1.35f)
        }
    }

    private fun fits(base: Float, availW: Int, availH: Int): Boolean {
        apply(base)
        if (hasArabic && arabicWords.any { arabicView.paint.measureText(it) > availW }) return false
        if (hasTranslit && translitWords.any { translitView.paint.measureText(it) > availW }) return false
        measureTexts(availW)
        return contentHeight() <= availH
    }

    private fun search(availW: Int, availH: Int) {
        val (lo, hi) = if (hasArabic) sp(ARABIC_MIN_SP) to sp(ARABIC_MAX_SP)
        else sp(ALONE_MIN_SP) to sp(ALONE_MAX_SP)
        drawScale = 1f
        if (availW <= 0) {
            fitSize = lo
            return
        }
        if (fits(hi, availW, availH)) {
            fitSize = hi
            return
        }
        var low = lo
        var high = hi
        if (!fits(low, availW, availH)) {
            // Nothing fits: the smallest size, scaled down to the room there is.
            fitSize = low
            apply(low)
            measureTexts(availW)
            val content = contentHeight()
            if (availH != Int.MAX_VALUE && content > 0) drawScale = min(1f, availH.toFloat() / content)
            return
        }
        repeat(12) {
            val mid = (low + high) / 2f
            if (fits(mid, availW, availH)) low = mid else high = mid
        }
        fitSize = low
    }

    private companion object {
        /** The Arabic's size range, in sp: as large as fits, but not a headline. */
        const val ARABIC_MIN_SP = 14f
        const val ARABIC_MAX_SP = 46f

        /** The transliteration alone is the dhikr, with its own range. */
        const val ALONE_MIN_SP = 14f
        const val ALONE_MAX_SP = 36f

        const val TRANSLIT_RATIO = 0.42f
        const val TRANSLIT_MIN_SP = 12f

        /** Space between the Arabic and the transliteration under it. */
        const val GAP_DP = 10f

        /** Line height of the Arabic, in times its size (the desktop card uses 1.6). */
        const val ARABIC_LINE_EM = 1.5f

        /** How far above the baseline the letters and their marks reach, in times the size. */
        const val ARABIC_INK_ASCENT_EM = 1.0f
    }
}
