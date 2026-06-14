import 'package:flutter/material.dart';

import '../models/board.dart';
import '../models/task.dart';
import '../services/board_storage_service.dart';
import '../services/home_widget_service.dart';
import '../widgets/task_card.dart';

// The main screen widget for the reminder board.
class ReminderBoardScreen extends StatefulWidget {
  const ReminderBoardScreen({super.key});

  @override
  State<ReminderBoardScreen> createState() => _ReminderBoardScreenState();
}

class _ReminderBoardScreenState extends State<ReminderBoardScreen> {
  List<Board> _boards = [];
  int _currentBoardIndex = 0;
  bool _isLoading = true;

  Board get _currentBoard => _boards[_currentBoardIndex];

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    final boards = await BoardStorageService.loadBoards();
    setState(() {
      _boards = boards;
      _currentBoardIndex = 0;
      _isLoading = false;
    });
  }

  // Single helper called after any mutation that should be reflected in
  // the home screen widget. Grid settings use saveBoards() directly
  // since the widget doesn't display layout information.
  Future<void> _saveAndUpdate() async {
    await BoardStorageService.saveBoards(_boards);
    await HomeWidgetService.updateWidget();
  }

  // --- Board management -----------------------------------------------

  void _switchToBoard(int index) {
    setState(() => _currentBoardIndex = index);
  }

  Future<void> _createBoard(String name) async {
    final newBoard = Board(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    setState(() {
      _boards.add(newBoard);
      _currentBoardIndex = _boards.length - 1;
    });
    await _saveAndUpdate();
  }

  Future<void> _renameCurrentBoard(String newName) async {
    setState(() => _currentBoard.name = newName);
    // No widget update needed — the widget doesn't display board names.
    await BoardStorageService.saveBoards(_boards);
  }

  Future<void> _deleteCurrentBoard() async {
    setState(() {
      _boards.removeAt(_currentBoardIndex);
      _currentBoardIndex = _currentBoardIndex.clamp(0, _boards.length - 1);
    });
    await _saveAndUpdate();
  }

  // ── Task management ───────────────────────────────────────────────────────

  Future<void> _addNewTask(String title) async {
    if (title.isNotEmpty) {
      setState(() => _currentBoard.tasks.add(Task(title: title)));
      await _saveAndUpdate();
    }
  }

  void _toggleTaskCompletion(int index, bool value) {
    setState(() => _currentBoard.tasks[index].isCompleted = value);
    _saveAndUpdate();
  }

  Future<void> _deleteTask(int index) async {
    setState(() => _currentBoard.tasks.removeAt(index));
    await _saveAndUpdate();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        // The title is a DropdownButton rather than static Text.
        // Setting underline to SizedBox() removes the default decoration
        // so it blends cleanly into the AppBar.
        title: DropdownButton<int>(
          value: _currentBoardIndex,
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          // _boards.asMap().entries gives us both the index and the Board
          // object together, which we need to set the DropdownMenuItem value
          // to an int (the index) while displaying the board's name.
          items: [
            ..._boards.asMap().entries.map(
              (entry) => DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value.name),
              ),
            ),
            // Sentinel value of -1 signals "create" rather than "switch".
            // It will never equal _currentBoardIndex, so it won't appear
            // selected, but it will trigger onChanged when tapped.
            const DropdownMenuItem<int>(
              value: -1,
              child: Text(
                '＋ Create new board',
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            if (value == -1) {
              _showCreateBoardDialog();
            } else {
              _switchToBoard(value);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline),
            tooltip: 'Rename board',
            onPressed: _showRenameBoardDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete board',
            onPressed: _showDeleteBoardDialog,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Grid settings',
            onPressed: _showGridSettingsDialog,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _currentBoard.tasks.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _currentBoard.crossAxisCount,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: _currentBoard.crossAxisCount > 3 ? 1.0 : 2.5,
        ),
        itemBuilder: (context, index) {
          return TaskCard(
            task: _currentBoard.tasks[index],
            onToggle: (value) => _toggleTaskCompletion(index, value),
            onDeleteRequested: () => _showDeleteConfirmationDialog(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddTaskDialog),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showCreateBoardDialog() async {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Board'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Board name'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                _createBoard(name);
              }
            },
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _showRenameBoardDialog() async {
    final controller = TextEditingController(text: _currentBoard.name);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Board'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Board name'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Rename'),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                _renameCurrentBoard(name);
              }
            },
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _showDeleteBoardDialog() async {
    // TODO: user should be able to delete their only board, but we will need UI for creating the first board
    // Guard: prevent the user from deleting their only board.
    if (_boards.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your only board.')),
      );
      return;
    }
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board?'),
        content: Text(
          'Are you sure you want to delete "${_currentBoard.name}"? '
          'All tasks on this board will be lost.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCurrentBoard();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text(
          'Are you sure you want to delete "${_currentBoard.tasks[index].title}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
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
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter task title'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              Navigator.of(context).pop();
              _addNewTask(controller.text);
            },
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _showGridSettingsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Grid Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Columns: ${_currentBoard.crossAxisCount}'),
              Slider(
                value: _currentBoard.crossAxisCount.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _currentBoard.crossAxisCount.toString(),
                onChanged: (value) {
                  setDialogState(
                    () => _currentBoard.crossAxisCount = value.toInt(),
                  );
                  setState(() => _currentBoard.crossAxisCount = value.toInt());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
                // Save the layout preference, but no widget update needed.
                BoardStorageService.saveBoards(_boards);
              },
            ),
          ],
        ),
      ),
    );
  }
}
