import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/home_widget_service.dart';
import '../services/task_storage_service.dart';
import '../widgets/task_card.dart';

// The main screen widget for the reminder board.
class ReminderBoardScreen extends StatefulWidget {
  const ReminderBoardScreen({super.key});

  @override
  State<ReminderBoardScreen> createState() => _ReminderBoardScreenState();
}

class _ReminderBoardScreenState extends State<ReminderBoardScreen> {
  // A list to hold the daily tasks.
  List<Task> _tasks = [];
  int _crossAxisCount = 2;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  _loadTasks() async {
    final loadedTasks = await TaskStorageService.loadTasks();
    if (loadedTasks != null) {
      setState(() {
        _tasks = loadedTasks;
      });
    }
  }

  Future<void> _addNewTask(String title) async {
    if (title.isNotEmpty) {
      setState(() {
        // Add a new task to the list.
        _tasks.add(Task(title: title));
      });
      // Save the updated tasks state.
      await TaskStorageService.saveTasks(_tasks);
      await HomeWidgetService.updateWidget();
    }
  }

  // Toggles the completion status of a task and saves the new state.
  void _toggleTaskCompletion(int index, bool value) {
    setState(() {
      _tasks[index].isCompleted = value;
    });
    // Save the tasks every time a switch is toggled.
    TaskStorageService.saveTasks(_tasks);
    HomeWidgetService.updateWidget();
  }

  Future<void> _deleteTask(int index) async {
    setState(() {
      _tasks.removeAt(index);
    });
    await TaskStorageService.saveTasks(_tasks);
    await HomeWidgetService.updateWidget();
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Task?"),
          content: Text(
            'Are you sure you want to delete "${_tasks[index].title}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask(index);
              },
            ),
          ],
        );
      },
    );
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
            icon: const Icon(Icons.grid_view),
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
          childAspectRatio: _crossAxisCount > 3
              ? 1.0
              : 2.5, // adjust to make tiles taller or wider
        ),
        itemBuilder: (context, index) {
          return TaskCard(
            task: _tasks[index],
            onToggle: (value) => _toggleTaskCompletion(index, value),
            onDeleteRequested: () => _showDeleteConfirmationDialog(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddTaskDialog),
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
