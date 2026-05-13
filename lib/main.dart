import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io';

import './screens/reminder_board_screen.dart';

// The main entry point for the Flutter application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
    await HomeWidget.setAppGroupId('com.speaksoft.reminderboard');
  }

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
