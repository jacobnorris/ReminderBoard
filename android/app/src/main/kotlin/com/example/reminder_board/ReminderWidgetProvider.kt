package com.example.reminder_board

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class ReminderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.reminder_widget)

        // Load shared preferences to get reminder data:
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val tasksJson = prefs.getString("flutter.tasks", "[]");
        val tasks = if (tasksJson != null && tasksJson.isNotEmpty()) {
            // Parse the JSON string to a list of tasks
            // Assuming you have a method to parse JSON to a List<String>
            parseTasksFromJson(tasksJson)
        } else {
            emptyList<String>()
        }
        // Set the text for the widget
        val tasksText = tasks.joinToString("\n")
        views.setTextViewText(R.id.widget_text, tasksText)
        // Set the widget layout
        views.setInt(R.id.widget_layout, "setBackgroundResource", R.drawable.widget_background)
        // Set the widget title
        views.setTextViewText(R.id.widget_title, "Reminder Board")
        // Set the widget title color
        views.setTextColor(R.id.widget_title, context.getColor(R.color.widget_title_color))
        // Set the widget text color
        views.setTextColor(R.id.widget_text, context.getColor(R.color.widget_text_color))

        // Set up the intent that starts the ReminderActivity
        val intent = Intent(context, ReminderActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)

        views.setOnClickPendingIntent(R.id.widget_layout, pendingIntent)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}