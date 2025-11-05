package com.afaqalspl.moshaf

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetLargeProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val allPrayers = widgetData.all.mapValues { it.value.toString() }
        val views = RemoteViews(context.packageName, R.layout.widget_large)

        val upcomingPrayer = widgetData.getString("prayer_name", "") ?: ""

        views.setTextViewText(R.id.title, "🕌 أوقات الصلاة")
        views.setTextViewText(R.id.date, "اليوم")

        fun setPrayerRow(nameId: Int, timeId: Int, name: String) {
            val time = allPrayers[name] ?: "--:--"
            views.setTextViewText(nameId, name)
            views.setTextViewText(timeId, time)

            // Highlight the upcoming prayer
            if (name == upcomingPrayer) {
                views.setTextColor(nameId, ContextCompat.getColor(context, android.R.color.holo_green_light))
                views.setTextColor(timeId, ContextCompat.getColor(context, android.R.color.holo_green_light))
            } else {
                views.setTextColor(nameId, ContextCompat.getColor(context, android.R.color.white))
                views.setTextColor(timeId, ContextCompat.getColor(context, android.R.color.white))
            }
        }

        // Set each prayer row
        setPrayerRow(R.id.prayer_name_1, R.id.prayer_time_1, "الفجر")
        setPrayerRow(R.id.prayer_name_2, R.id.prayer_time_2, "الظهر")
        setPrayerRow(R.id.prayer_name_3, R.id.prayer_time_3, "العصر")
        setPrayerRow(R.id.prayer_name_4, R.id.prayer_time_4, "المغرب")
        setPrayerRow(R.id.prayer_name_5, R.id.prayer_time_5, "العشاء")

        // Update all widget instances
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
