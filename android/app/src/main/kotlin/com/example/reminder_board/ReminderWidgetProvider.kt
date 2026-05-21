package com.speaksoft.reminderboard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import org.json.JSONArray

class ReminderWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_TOGGLE_TASK = "com.speaksoft.reminderboard.TOGGLE_TASK"
        const val EXTRA_TASK_INDEX = "task_index"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    // Called for both APPWIDGET_UPDATE and our custom TOGGLE_TASK action.
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_TASK) {
            val index = intent.getIntExtra(EXTRA_TASK_INDEX, -1)
            if (index >= 0) {
                toggleTask(context, index)
                // Redraw all instances of this widget after toggling.
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, ReminderWidgetProvider::class.java)
                )
                onUpdate(context, manager, ids)
            }
        }
    }

    private fun toggleTask(context: Context, index: Int) {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val tasksJson = prefs.getString("flutter.tasks", "[]") ?: "[]"
        try {
            val array = JSONArray(tasksJson)
            if (index < array.length()) {
                val task = array.getJSONObject(index)
                task.put("isCompleted", !task.optBoolean("isCompleted", false))
            }
            prefs.edit().putString("flutter.tasks", array.toString()).apply()
        } catch (e: Exception) {
            // Leave data unchanged if parsing fails.
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.reminder_widget)

        // Point the ListView at ReminderWidgetService, which supplies the rows.
        val serviceIntent = Intent(context, ReminderWidgetService::class.java)
        views.setRemoteAdapter(R.id.widget_task_list, serviceIntent)
        views.setEmptyView(R.id.widget_task_list, R.id.widget_title)

        // A PendingIntent template is required when using setRemoteAdapter.
        // Each row's fillInIntent (set in the factory) will supply the index.
        // FLAG_MUTABLE is required here so the system can merge the fillInIntent.
        val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_MUTABLE else 0

        val toggleIntent = Intent(context, ReminderWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_TASK
        }
        val togglePendingIntent = PendingIntent.getBroadcast(
            context, 0, toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag
        )
        views.setPendingIntentTemplate(R.id.widget_task_list, togglePendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        // Tell the ListView that its underlying data has changed.
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_task_list)
    }
}
