import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/models/note_database.dart';
import 'package:studybuddy/screens/homepage.dart';
import 'package:studybuddy/shared/app_palette.dart';
import 'package:studybuddy/shared/page_title.dart';
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

class _PlannerBoardState extends State<PlannerBoard> with SingleTickerProviderStateMixin {
  static const String _plannerPrefix = '__planner__::';

  final NoteDatabase _database = NoteDatabase();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 24,
                  right: 24,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppPalette.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.event_note,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isEditing ? 'Edit Planner Task' : 'New Planner Task',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Task Title',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What is your plan?',
                        hintStyle: TextStyle(
                          color: AppPalette.textMuted.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: AppPalette.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Location (Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Where will this take place?',
                        hintStyle: TextStyle(
                          color: AppPalette.textMuted.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: AppPalette.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black38),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Details (Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add any extra notes...',
                        hintStyle: TextStyle(
                          color: AppPalette.textMuted.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: AppPalette.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final DateTime now = DateTime.now();
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(now.year - 3),
                          lastDate: DateTime(now.year + 5),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppPalette.primary,
                                  onPrimary: Colors.white,
                                  surface: AppPalette.surface,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
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
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppPalette.primary,
                                  onPrimary: Colors.white,
                                  surface: AppPalette.surface,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppPalette.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                DateFormat('EEE, d MMM y • hh:mm a').format(selectedDateTime),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar,
                              size: 18,
                              color: AppPalette.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (isEditing)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _deleteEntry(existingEntry!);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        if (isEditing) const SizedBox(width: 12),
                        Expanded(
                          flex: isEditing ? 2 : 1,
                          child: FilledButton.icon(
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

                              Navigator.pop(context);
                            },
                            icon: Icon(isEditing ? Icons.save : Icons.add),
                            label: Text(isEditing ? 'Save Changes' : 'Create Task'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 28,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Task?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${entry.note.title}" will be permanently removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _database.removeNote(entry.index);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
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
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const Homepage()),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        child: TaskBar(),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const StudyBuddyPageTitle(
                  title: 'THE\nPLANNER',
                  subtitle: 'Plan Your Sessions',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 14),
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 48,
                                color: AppPalette.textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No planner tasks yet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap + to add your first task.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppPalette.textMuted.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
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
                              color: Color(entry.note.blockColorValue).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppPalette.primaryBorder, width: 1),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppPalette.primarySoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        DateFormat('hh:mm a').format(entry.date),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (entry.payload.location.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          entry.payload.location,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (entry.payload.details.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.payload.details,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openPlannerEditor(existingEntry: entry),
                                      icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteEntry(entry),
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
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