import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(NoteDataAdapter());
  await Hive.openBox<NoteData>('notesBox');
  await Hive.openBox('focusBox');
  await Hive.openBox('profileBox');

  runApp(const StudyBuddyApp());
}

class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}