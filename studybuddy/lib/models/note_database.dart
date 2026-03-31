import 'package:hive_flutter/adapters.dart';
import 'package:studybuddy/models/note_data.dart';

class NoteDatabase {

  /// Use the same generic type as the box is opened with.
  ///
  /// Calling `Hive.box(...)` with a mismatched generic type will throw a
  /// `HiveError` when the box is already open (which is what happens during
  /// normal app startup, since `main()` opens the box as `Box<NoteData>`).
  late final Box<NoteData> box;

  NoteDatabase() {
    box = Hive.box<NoteData>("notesBox");
  }

  void addNote(NoteData data) {
    box.add(data);
  }

  void removeNote(int index) {
    box.deleteAt(index);
  }

  NoteData? getNote(int index) {
    return box.getAt(index);
  }

  List<NoteData> getAllNotes() {
    return box.values.toList().cast<NoteData>();
  }

  void updateNote(int index, NoteData data) {
    box.putAt(index, data);
  }


}
