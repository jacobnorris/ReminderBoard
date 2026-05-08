import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/task.dart';

class TaskStorageService {
  // Asynchronously loads the tasks from shared preferences.
  static Future<List<Task>?> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve the JSON string of tasks from storage.
    final String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      // Decode the JSON string back into a list of maps.
      final List<dynamic> tasksList = jsonDecode(tasksJson);

      return tasksList.map((taskMap) => Task.fromMap(taskMap)).toList();
    } else {
      return null;
    }
  }

  // Asynchronously saves the current state of tasks to shared preferences.
  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert the list of Task objects to a list of maps.
    final List<Map<String, dynamic>> tasksList = tasks
        .map((task) => task.toMap())
        .toList();
    // Encode the list of maps into a JSON string.
    final String tasksJson = jsonEncode(tasksList);
    // Store the JSON string.
    await prefs.setString('tasks', tasksJson);
  }
}
