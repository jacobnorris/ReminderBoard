import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDeleteRequested;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onDeleteRequested,
      onSecondaryTap: onDeleteRequested,
      child: Card(
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
            onChanged: onToggle,
            activeThumbColor: Colors.teal,
          ),
        ),
      ),
    );
  }
}
