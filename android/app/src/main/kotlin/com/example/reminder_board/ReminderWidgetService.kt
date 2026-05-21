package com.speaksoft.reminderboard

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class ReminderWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TaskRemoteViewsFactory(applicationContext)
}

private data class TaskItem(val title: String, val isCompleted: Boolean)

class TaskRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private var tasks: List<TaskItem> = emptyList()

    override fun onCreate() {
        loadTasks()
    }

    override fun onDataSetChanged() {
        loadTasks()
    }

    override fun onDestroy() {}

    override fun getCount(): Int = tasks.size
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
    override fun getLoadingView(): RemoteViews? = null

    override fun getViewAt(position: Int): RemoteViews {
        val task = tasks[position]
        val views = RemoteViews(context.packageName, R.layout.reminder_widget_item)

        views.setTextViewText(R.id.task_title, task.title)
        views.setTextViewText(
            R.id.task_status_icon,
            if (task.isCompleted) "✓" else "•"
        )

        // fillInIntent carries this row's index into the template PendingIntent
        // that was set in ReminderWidgetProvider.updateAppWidget().
        val fillInIntent = Intent().apply {
            putExtra(ReminderWidgetProvider.EXTRA_TASK_INDEX, position)
        }
        views.setOnClickFillInIntent(R.id.task_item_layout, fillInIntent)

        return views
    }

    private fun loadTasks() {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val json = prefs.getString("flutter.tasks", "[]") ?: "[]"
        tasks = try {
            val array = JSONArray(json)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                TaskItem(
                    title = obj.getString("title"),
                    isCompleted = obj.optBoolean("isCompleted", false)
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
