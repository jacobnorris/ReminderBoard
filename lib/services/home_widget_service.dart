import 'package:home_widget/home_widget.dart';

/// Tells the Android home screen widget to redraw itself.
/// Call this after any change that has already been persisted
/// via TaskStorageService.saveTasks(), since the widget reads
/// directly from the same SharedPreferences file.
class HomeWidgetService {
  static const String _qualifiedAndroidName =
      'com.speaksoft.reminderboard.ReminderBoardWidgetProvider';

  static Future<void> updateWidget() async {
    await HomeWidget.updateWidget(qualifiedAndroidName: _qualifiedAndroidName);
  }
}
