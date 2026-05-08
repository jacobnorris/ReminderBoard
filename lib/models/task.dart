// A model class to represent a single task.
class Task {
  String title;
  bool isCompleted;

  Task({required this.title, this.isCompleted = false});

  // Factory constructor to create a Task from a map (used for decoding from JSON).
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(title: map['title'], isCompleted: map['isCompleted']);
  }

  // Method to convert a Task instance to a map (used for encoding to JSON).
  Map<String, dynamic> toMap() {
    return {'title': title, 'isCompleted': isCompleted};
  }
}
