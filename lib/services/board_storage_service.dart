import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board.dart';
import '../models/task.dart';

class BoardStorageService {
  static const _boardsKey = 'boards';

  // the old single-board key. only read during one-time migration
  static const _legacyTasksKey = 'tasks';

  static Future<List<Board>> loadBoards() async {
    final prefs = await SharedPreferences.getInstance();

    final boardsJson = prefs.getString(_boardsKey);
    if (boardsJson != null) {
      final list = jsonDecode(boardsJson) as List<dynamic>;
      return list.map((m) => Board.fromMap(m as Map<String, dynamic>)).toList();
    }

    // One-time migration: if the old single-board 'tasks' key exists,
    // wrap those tasks into a first board and save in the new format
    // This runs exactly once - on the first launch after the update

    // TODO we don't need the one-time migration - no actual users are using this app yet.
    final legacyJson = prefs.getString(_legacyTasksKey);
    if (legacyJson != null) {
      final tasks = (jsonDecode(legacyJson) as List<dynamic>)
          .map((m) => Task.fromMap(m as Map<String, dynamic>))
          .toList();
      final migratedBoard = Board(
        id: '1',
        name: 'Daily Reminders',
        tasks: tasks,
      );
      await saveBoards([migratedBoard]);
      return [migratedBoard];
    }

    // Fresh install: seed with a default board so the screen is not empty
    final defaultBoard = Board(id: '1', name: 'Daily Reminders', tasks: []);
    await saveBoards([defaultBoard]);
    return [defaultBoard];
  }

  static Future<void> saveBoards(List<Board> boards) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _boardsKey,
      jsonEncode(boards.map((b) => b.toMap()).toList()),
    );

    // TODO FEATURE: support multiple widgets showing different boards
    // Keep the legacy 'tasks' key in sync with the first board's tasks.
    // The Android home screen widget reads from 'flutter.tasks', so this
    // lets it always show the first board with no native code changes needed.
    if (boards.isNotEmpty) {
      await prefs.setString(
        _legacyTasksKey,
        jsonEncode(boards.first.tasks.map((t) => t.toMap()).toList()),
      );
    }
  }
}
