import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/models/note_database.dart';
import 'package:studybuddy/shared/planner_tabs.dart';
import 'package:studybuddy/shared/taskbar.dart';

class PlannerBoard extends StatefulWidget {
  const PlannerBoard({
    super.key,
    required this.selectedTab,
  });

  final String selectedTab;

  @override
  State<PlannerBoard> createState() => _PlannerBoardState();
}

class _PlannerBoardState extends State<PlannerBoard> {
  static const String _plannerPrefix = '__planner__::';

  final NoteDatabase _database = NoteDatabase();

  Future<void> _openPlannerEditor({_PlannerEntry? existingEntry}) async {
    final bool isEditing = existingEntry != null;

    final TextEditingController titleController = TextEditingController(
      text: existingEntry?.note.title ?? '',
    );

    final _PlannerPayload? existingPayload =
        existingEntry == null ? null : _decodePlannerPayload(existingEntry.note.content);

    final TextEditingController locationController = TextEditingController(
      text: existingPayload?.location ?? '',
    );

    final TextEditingController detailsController = TextEditingController(
      text: existingPayload?.details ?? '',
    );

    DateTime selectedDateTime =
        existingEntry?.date ?? DateTime.now().add(const Duration(minutes: 30));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Planner Task' : 'New Planner Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Details'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('EEE, d MMM y • hh:mm a').format(selectedDateTime),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime now = DateTime.now();
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime(now.year - 3),
                              lastDate: DateTime(now.year + 5),
                            );

                            if (pickedDate == null) {
                              return;
                            }

                            if (!context.mounted) {
                              return;
                            }

                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                            );

                            if (pickedTime == null) {
                              return;
                            }

                            setDialogState(() {
                              selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          },
                          child: const Text('Pick'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final String title = titleController.text.trim();
                    final String location = locationController.text.trim();
                    final String details = detailsController.text.trim();

                    if (title.isEmpty) {
                      return;
                    }

                    final NoteData note = NoteData(
                      title: title,
                      content: _encodePlannerPayload(
                        location: location,
                        details: details,
                      ),
                      date: selectedDateTime.toIso8601String(),
                      blockColorValue: existingEntry?.note.blockColorValue ?? 0xFF1A26FF,
                    );

                    if (isEditing) {
                      _database.updateNote(existingEntry.index, note);
                    } else {
                      _database.addNote(note);
                    }

                    Navigator.pop(dialogContext);
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    locationController.dispose();
    detailsController.dispose();
  }

  Future<void> _deleteEntry(_PlannerEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: const Text('This task will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _database.removeNote(entry.index);
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  DateTime? _parseDate(String value) {
    final DateTime? isoParsed = DateTime.tryParse(value);
    if (isoParsed != null) {
      return isoParsed;
    }

    try {
      return DateFormat('y/M/d').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  String _encodePlannerPayload({required String location, required String details}) {
    return '$_plannerPrefix$location||$details';
  }

  _PlannerPayload? _decodePlannerPayload(String content) {
    if (!content.startsWith(_plannerPrefix)) {
      return null;
    }

    final String raw = content.substring(_plannerPrefix.length);
    final List<String> parts = raw.split('||');

    final String location = parts.isEmpty ? '' : parts.first;
    final String details = parts.length < 2 ? '' : parts.sublist(1).join('||');

    return _PlannerPayload(location: location, details: details);
  }

  List<_PlannerEntry> _buildEntries(Box<NoteData> box) {
    final List<_PlannerEntry> entries = <_PlannerEntry>[];

    for (int index = 0; index < box.length; index++) {
      final NoteData? note = box.getAt(index);
      if (note == null) {
        continue;
      }

      final _PlannerPayload? payload = _decodePlannerPayload(note.content);
      final DateTime? parsedDate = _parseDate(note.date);

      if (payload == null || parsedDate == null) {
        continue;
      }

      entries.add(
        _PlannerEntry(
          index: index,
          note: note,
          payload: payload,
          date: parsedDate,
        ),
      );
    }

    entries.sort((a, b) => a.date.compareTo(b.date));

    if (widget.selectedTab == 'all' || widget.selectedTab.isEmpty) {
      return entries;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));

    if (widget.selectedTab == 'today') {
      return entries
          .where((entry) =>
              entry.date.year == today.year &&
              entry.date.month == today.month &&
              entry.date.day == today.day)
          .toList();
    }

    if (widget.selectedTab == 'tomorrow') {
      return entries
          .where((entry) =>
              entry.date.year == tomorrow.year &&
              entry.date.month == tomorrow.month &&
              entry.date.day == tomorrow.day)
          .toList();
    }

    return entries;
  }

  Widget _buildHeader() {
    final DateTime now = DateTime.now();

    DateTime? headerDate;
    if (widget.selectedTab == 'today') {
      headerDate = now;
    } else if (widget.selectedTab == 'tomorrow') {
      headerDate = now.add(const Duration(days: 1));
    }

    if (headerDate == null) {
      return const SizedBox(height: 6);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('EEEE').format(headerDate),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('d MMM').format(headerDate).toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<NoteData> box = Hive.box<NoteData>('notesBox');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      bottomNavigationBar: const BottomAppBar(child: TaskBar()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'THE\nPLANNER',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              PlannerTabs(
                selectedTab: widget.selectedTab,
                onAdd: () {
                  _openPlannerEditor();
                },
              ),
              _buildHeader(),
              Expanded(
                child: ValueListenableBuilder<Box<NoteData>>(
                  valueListenable: box.listenable(),
                  builder: (context, plannerBox, _) {
                    final List<_PlannerEntry> entries = _buildEntries(plannerBox);

                    if (entries.isEmpty) {
                      return const Center(
                        child: Text(
                          'No planner tasks yet. Tap + to add one.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final _PlannerEntry entry = entries[index];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(entry.note.blockColorValue).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.black45, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.note.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('hh:mm a').format(entry.date),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (entry.payload.location.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 18),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        entry.payload.location,
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                              if (entry.payload.details.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(entry.payload.details),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _openPlannerEditor(existingEntry: entry),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteEntry(entry),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerEntry {
  const _PlannerEntry({
    required this.index,
    required this.note,
    required this.payload,
    required this.date,
  });

  final int index;
  final NoteData note;
  final _PlannerPayload payload;
  final DateTime date;
}

class _PlannerPayload {
  const _PlannerPayload({
    required this.location,
    required this.details,
  });

  final String location;
  final String details;
}