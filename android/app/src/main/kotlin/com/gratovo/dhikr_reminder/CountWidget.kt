package com.gratovo.dhikr_reminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * The home-screen widget: today's total and the dhikr being counted. One tap
 * anywhere on it counts one. It is redrawn when something changes (a count, a
 * reminder, a pause), never on a timer, so it costs the battery nothing.
 */
class CountWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, render(context))
    }

    companion object {
        private const val MAX_CHARS = 120

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, CountWidget::class.java))
            if (ids.isEmpty()) return
            val views = render(context)
            for (id in ids) manager.updateAppWidget(id, views)
        }

        private fun render(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_count)
            val focus = ReminderStore.focus(context)
            val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            if (focus == null) {
                // Nothing to count yet: the widget says so and opens the app.
                views.setTextViewText(R.id.widget_dhikr, Surfaces.label(context, "openApp", R.string.widget_open))
                views.setViewVisibility(R.id.widget_total, View.GONE)
                views.setViewVisibility(R.id.widget_caption, View.GONE)
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(
                        context,
                        1,
                        Intent(context, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                        flags,
                    ),
                )
                return views
            }
            views.setTextViewText(R.id.widget_dhikr, focus.text.take(MAX_CHARS))
            views.setTextViewText(R.id.widget_total, ReminderStore.todayTotal(context).toString())
            views.setTextViewText(R.id.widget_caption, Surfaces.label(context, "today", R.string.widget_today))
            views.setViewVisibility(R.id.widget_total, View.VISIBLE)
            views.setViewVisibility(R.id.widget_caption, View.VISIBLE)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getBroadcast(
                    context,
                    2,
                    Intent(context, SurfaceReceiver::class.java).setAction(Surfaces.ACTION_COUNT),
                    flags,
                ),
            )
            return views
        }
    }
}
