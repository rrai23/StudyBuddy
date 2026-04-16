import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/models/note_database.dart';
import 'package:studybuddy/shared/app_palette.dart';
import 'package:studybuddy/shared/page_title.dart';
import 'package:studybuddy/shared/taskbar.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  static const String plannerPrefix = '__planner__::';
  static const String todoPrefix = '__studybuddy_home_todo__::';
  static const String legacyTodoPrefix = '__todo__::';
  static const int defaultBlockColorValue = 0xFF2196F3;

  final NoteDatabase database = NoteDatabase();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final List<Color> availableColors = const [
    Color(0xFF2196F3),
    Color(0xFF26A69A),
    Color(0xFFFFB300),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF8D6E63),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
  ];

  int selectedColorValue = defaultBlockColorValue;

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void openNoteEditor({NoteData? existingNote, int? noteIndex}) {
    final bool isEditing = existingNote != null && noteIndex != null;

    titleController.text = isEditing ? existingNote.title : '';
    contentController.text = isEditing ? existingNote.content : '';
    selectedColorValue = isEditing
      ? existingNote.blockColorValue
      : defaultBlockColorValue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                width: 750,
                height: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      isEditing ? 'Edit Note' : 'Create A New Note',
                      style: GoogleFonts.montserrat(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: titleController,
                        cursorColor: Colors.black,
                        decoration: const InputDecoration(
                          focusColor: Colors.black,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                          label: Text('Title'),
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: contentController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 12,
                        cursorColor: Colors.black,
                        decoration: const InputDecoration(
                          label: Text('Write your note here'),
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          focusColor: Colors.black,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Block Color',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: availableColors.map((color) {
                        final bool isSelected = selectedColorValue == color.toARGB32();
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorValue = color.toARGB32();
                            });
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.white,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        final NoteData note = NoteData(
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          date:
                              '${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
                          blockColorValue: selectedColorValue,
                        );

                        if (isEditing) {
                          database.updateNote(noteIndex, note);
                        } else {
                          database.addNote(note);
                        }

                        titleController.clear();
                        contentController.clear();

                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 8,
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Submit',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void openNoteViewer(NoteData noteData, int noteIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 3),
            ),
            width: 750,
            height: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  noteData.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      Text(
                        noteData.content,
                        style: GoogleFonts.montserrat(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 8,
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        openNoteEditor(existingNote: noteData, noteIndex: noteIndex);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        elevation: 8,
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.edit),
                    ),
                    FilledButton(
                      onPressed: () {
                        database.removeNote(noteIndex);
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 8,
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.delete),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<NoteData> box = Hive.box<NoteData>('notesBox');
    final List<_NoteRecord> notes = <_NoteRecord>[];

    for (int index = 0; index < box.length; index++) {
      final NoteData? note = box.getAt(index);
      if (note == null) {
        continue;
      }

      if (note.content.startsWith(plannerPrefix) ||
          note.content.startsWith(todoPrefix) ||
          note.content.startsWith(legacyTodoPrefix)) {
        continue;
      }

      notes.add(_NoteRecord(index: index, noteData: note));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: AppPalette.background,
      bottomNavigationBar: const BottomAppBar(
        child: TaskBar(),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          StudyBuddyPageTitle(
            title: 'THE\nNOTES',
            subtitle: 'Capture Ideas',
            trailing: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.primary,
              ),
              child: IconButton(
                onPressed: () => openNoteEditor(),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemBuilder: (context, index) {
                final _NoteRecord record = notes[index];
                return NoteContainer(
                  noteData: record.noteData,
                  onTap: () => openNoteViewer(record.noteData, record.index),
                );
              },
              itemCount: notes.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRecord {
  const _NoteRecord({
    required this.index,
    required this.noteData,
  });

  final int index;
  final NoteData noteData;
}

class NoteContainer extends StatelessWidget {
  const NoteContainer({
    required this.noteData,
    required this.onTap,
    super.key,
  });

  final NoteData noteData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 175,
            height: 150,
            decoration: BoxDecoration(
              color: Color(noteData.blockColorValue),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
        ),
        Text(
          noteData.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        Text(noteData.date),
      ],
    );
  }
}
