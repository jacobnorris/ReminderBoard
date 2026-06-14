import 'task.dart';

class Board {
  final String id;
  String name;
  List<Task> tasks;
  int crossAxisCount;

  Board({
    required this.id,
    required this.name,
    List<Task>? tasks,
    this.crossAxisCount = 2,
  }) : tasks = tasks ?? [];

  factory Board.fromMap(Map<String, dynamic> map) {
    return Board(
      id: map['id'] as String,
      name: map['name'] as String,
      tasks: (map['tasks'] as List<dynamic>)
          .map((task) => Task.fromMap(task as Map<String, dynamic>))
          .toList(),
      crossAxisCount: map['crossAxisCount'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'crossAxisCount': crossAxisCount,
    };
  }
}
