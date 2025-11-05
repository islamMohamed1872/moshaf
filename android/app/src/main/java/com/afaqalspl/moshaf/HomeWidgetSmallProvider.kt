package com.afaqalspl.moshaf

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetSmallProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val prayerName = widgetData.getString("prayer_name", "الصلاة القادمة")
        val prayerTime = widgetData.getString("prayer_time", "--:--")

        val views = RemoteViews(context.packageName, R.layout.widget_small)
        views.setTextViewText(R.id.prayer_name, "🕌 $prayerName")
        views.setTextViewText(R.id.prayer_time, prayerTime)
        views.setTextViewText(R.id.prayer_hint, "حان وقت الصلاة ⏱️")

        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
