import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/screens/notes.dart';

void main() async {

  await Hive.initFlutter();
  Hive.registerAdapter(NoteDataAdapter());
  await Hive.openBox<NoteData>('notesBox');


  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Notes(),
    )
  );
}