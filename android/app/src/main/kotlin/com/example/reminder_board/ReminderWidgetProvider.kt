package com.example.reminder_board

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

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
        val tasksJson = prefs.getString("flutter.tasks", "[]") ?: "[]"
        val tasks = parseTasksFromJson(tasksJson)

        // Set the text for the widget
        val displayText = if (tasks.isEmpty()) "No tasks yet." else tasks.joinToString("\n")
        views.setTextViewText(R.id.widget_title, "Reminder Board")
        views.setTextViewText(R.id.widget_text, displayText)

        // Tapping the widget opens the ReminderActivity
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_layout, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun parseTasksFromJson(json: String): List<String> {
        val result = mutableListOf<String>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val title = obj.getString("title")
                val isCompleted = obj.optBoolean("isCompleted", false)
                // Use a checkmark for done tasks and a bullet for pending ones.
                val prefix = if (isCompleted) "✓ " else "• "
                result.add("$prefix$title")
            }
        } catch (e: Exception) {
            result.add("Could not load tasks")
        }
        return result
    }
}
