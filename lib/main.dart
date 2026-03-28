import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// The main entry point for the Flutter application.
void main() {
  runApp(const ReminderBoardApp());
}

// The root widget of the application.
class ReminderBoardApp extends StatelessWidget {
  const ReminderBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder Board',
      // The theme applies a visual styling to the entire app.
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // The home property sets the default screen of the app.
      home: const ReminderBoardScreen(),
    );
  }
}

// A model class to represent a single task.
class Task {
  String title;
  bool isCompleted;

  Task({required this.title, this.isCompleted = false});

  // Factory constructor to create a Task from a map (used for decoding from JSON).
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      isCompleted: map['isCompleted'],
    );
  }

  // Method to convert a Task instance to a map (used for encoding to JSON).
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}

// The main screen widget for the reminder board.
class ReminderBoardScreen extends StatefulWidget {
  const ReminderBoardScreen({super.key});

  @override
  State<ReminderBoardScreen> createState() => _ReminderBoardScreenState();
}

class _ReminderBoardScreenState extends State<ReminderBoardScreen> {
  // A list to hold the daily tasks.
  List<Task> _tasks = [
    Task(title: 'Take medication'),
    Task(title: 'Walk the dog'),
    Task(title: 'Water the plants'),
    Task(title: 'Check the mail'),
    Task(title: 'Read for 15 minutes'),
    Task(title: 'Tidy up the kitchen'),
  ];
  int _crossAxisCount = 2;

  @override
  void initState() {
    super.initState();
    // Load the saved task states when the widget is first created.
    _loadTasksState();
  }

  // Asynchronously loads the tasks from shared preferences.
  Future<void> _loadTasksState() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve the JSON string of tasks from storage.
    final String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      // Decode the JSON string back into a list of maps.
      final List<dynamic> tasksList = jsonDecode(tasksJson);
      setState(() {
        // Create Task objects from the decoded map data.
        _tasks = tasksList.map((taskMap) => Task.fromMap(taskMap)).toList();
      });
    }
  }

  // Asynchronously saves the current state of tasks to shared preferences.
  Future<void> _saveTasksState() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert the list of Task objects to a list of maps.
    final List<Map<String, dynamic>> tasksList =
    _tasks.map((task) => task.toMap()).toList();
    // Encode the list of maps into a JSON string.
    final String tasksJson = jsonEncode(tasksList);
    // Store the JSON string.
    await prefs.setString('tasks', tasksJson);
  }

  Future<void> _addNewTask(String title) async {
    if (title.isNotEmpty) {
      setState(() {
        // Add a new task to the list.
        _tasks.add(Task(title: title));
      });
      // Save the updated tasks state.
      await _saveTasksState();
    }
  }

  // Toggles the completion status of a task and saves the new state.
  void _toggleTaskCompletion(int index, bool value) {
    setState(() {
      _tasks[index].isCompleted = value;
    });
    // Save the tasks every time a switch is toggled.
    _saveTasksState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reminder Board'),
        actions: [
          IconButton(
            onPressed: () {
              // Show a simple dialog to pick 1-10 columns
              _showGridSettingsDialog();
            },
            icon: const Icon(Icons.grid_view)
          ),
        ],
      ),
      // The body of the Scaffold is a ListView that displays the tasks.
      body: GridView.builder(
        // Add some padding around the list.
        padding: const EdgeInsets.all(8.0),
        itemCount: _tasks.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: _crossAxisCount > 3 ? 1.0 : 2.5 // adjust to make tiles taller or wider
        ),
        itemBuilder: (context, index) {
          final task = _tasks[index];
          // Each item in the list is a Card for better visual separation.
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ListTile(
              // The title of the list tile is the task's title.
              title: Text(
                task.title,
                style: TextStyle(
                  // Visually indicate completion with a line-through style.
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              // The trailing widget is the switch to mark the task as complete.
              trailing: Switch(
                value: task.isCompleted,
                onChanged: (value) => _toggleTaskCompletion(index, value),
                activeThumbColor: Colors.teal,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    String newTaskTitle = '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            onChanged: (value) {
              newTaskTitle = value;
            },
            decoration: const InputDecoration(hintText: 'Enter task title'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addNewTask(newTaskTitle);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGridSettingsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // We use StatefulBuilder so the slider moves smoothly inside the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Grid Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Columns: $_crossAxisCount'),
                  Slider(
                    value: _crossAxisCount.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _crossAxisCount.toString(),
                    onChanged: (double value) {
                      // Update the dialog's local state so the slider moves
                      setDialogState(() {
                        _crossAxisCount = value.toInt();
                      });
                      // Update the main app state so the grid changes in the background
                      setState(() {
                        _crossAxisCount = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Done'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
