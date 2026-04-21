import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/models/note_database.dart';
import 'package:studybuddy/screens/planner_empty_screen.dart';
import 'package:studybuddy/screens/profile.dart';
import 'package:studybuddy/shared/app_palette.dart';
import 'package:studybuddy/shared/page_title.dart';
import 'package:studybuddy/shared/taskbar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  static const String plannerPrefix = '__planner__::';
  static const String todoPrefix = '__studybuddy_home_todo__::';
  static const String legacyTodoPrefix = '__todo__::';

  final NoteDatabase database = NoteDatabase();

  late AnimationController _greetingController;
  late Animation<double> _greetingFade;
  late AnimationController _cardController;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _greetingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _greetingController,
        curve: Curves.easeOut,
      ),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _cardScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOut,
      ),
    );
    _greetingController.forward();
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Uint8List? _photoBytes(String? base64Photo) {
    if (base64Photo == null || base64Photo.isEmpty) {
      return null;
    }

    try {
      return base64Decode(base64Photo);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }

    try {
      return DateFormat('y/M/d').parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  List<DateTime> _readFocusSessionDays(Box focusBox) {
    final dynamic rawSessions = focusBox.get('focusSessions');
    if (rawSessions is! List) {
      return <DateTime>[];
    }

    final List<DateTime> days = <DateTime>[];
    for (final dynamic raw in rawSessions) {
      if (raw is! Map) {
        continue;
      }

      final String endRaw = raw['end']?.toString() ?? '';
      final DateTime? endAt = DateTime.tryParse(endRaw);
      if (endAt == null) {
        continue;
      }

      days.add(DateTime(endAt.year, endAt.month, endAt.day));
    }

    return days;
  }

  int _focusStreakDays(Box focusBox) {
    final Set<DateTime> uniqueDays = _readFocusSessionDays(focusBox).toSet();
    if (uniqueDays.isEmpty) {
      return 0;
    }

    final DateTime now = DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, now.day);
    int streak = 0;

    while (uniqueDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _todayFocusSeconds(Box focusBox) {
    final dynamic rawSessions = focusBox.get('focusSessions');
    if (rawSessions is! List) {
      return 0;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    int totalSeconds = 0;

    for (final dynamic raw in rawSessions) {
      if (raw is! Map) {
        continue;
      }

      final DateTime? endAt = DateTime.tryParse(raw['end']?.toString() ?? '');
      if (endAt == null) {
        continue;
      }

      final DateTime endDay = DateTime(endAt.year, endAt.month, endAt.day);
      if (endDay != today) {
        continue;
      }

      totalSeconds += (raw['durationSeconds'] as int?) ?? 0;
    }

    return totalSeconds;
  }

  _TodoPayload? _decodeTodo(String content) {
    String? matchedPrefix;

    if (content.startsWith(todoPrefix)) {
      matchedPrefix = todoPrefix;
    } else if (content.startsWith(legacyTodoPrefix)) {
      matchedPrefix = legacyTodoPrefix;
    }

    if (matchedPrefix == null) {
      return null;
    }

    final String raw = content.substring(matchedPrefix.length);
    final List<String> parts = raw.split('||');

    final String details = parts.isEmpty ? '' : parts.first;
    final bool isDone = parts.length > 1 && parts[1].toLowerCase() == 'true';

    return _TodoPayload(details: details, isDone: isDone);
  }

  String _encodeTodo({required String details, required bool isDone}) {
    return '$todoPrefix$details||$isDone';
  }

  _PlannerPayload? _decodePlanner(String content) {
    if (!content.startsWith(plannerPrefix)) {
      return null;
    }

    final String raw = content.substring(plannerPrefix.length);
    final List<String> parts = raw.split('||');
    final String location = parts.isEmpty ? '' : parts.first;
    final String details = parts.length < 2 ? '' : parts.sublist(1).join('||');

    return _PlannerPayload(location: location, details: details);
  }

  List<_TodoEntry> _buildTodoEntries(Box<NoteData> box) {
    final List<_TodoEntry> todos = <_TodoEntry>[];

    for (int index = 0; index < box.length; index++) {
      final NoteData? note = box.getAt(index);
      if (note == null) {
        continue;
      }

      final _TodoPayload? payload = _decodeTodo(note.content);
      if (payload == null) {
        continue;
      }

      final DateTime createdAt = _parseDate(note.date) ?? DateTime.now();

      todos.add(
        _TodoEntry(
          index: index,
          note: note,
          payload: payload,
          createdAt: createdAt,
        ),
      );
    }

    todos.sort((a, b) {
      if (a.payload.isDone != b.payload.isDone) {
        return a.payload.isDone ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return todos;
  }

  List<_PlannerEntry> _buildPlannerPreview(Box<NoteData> box) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime inSevenDays = today.add(const Duration(days: 7));

    final List<_PlannerEntry> planners = <_PlannerEntry>[];

    for (int index = 0; index < box.length; index++) {
      final NoteData? note = box.getAt(index);
      if (note == null) {
        continue;
      }

      final _PlannerPayload? payload = _decodePlanner(note.content);
      final DateTime? date = _parseDate(note.date);

      if (payload == null || date == null) {
        continue;
      }

      if (date.isBefore(today) || date.isAfter(inSevenDays)) {
        continue;
      }

      planners.add(
        _PlannerEntry(
          index: index,
          note: note,
          payload: payload,
          date: date,
        ),
      );
    }

    planners.sort((a, b) => a.date.compareTo(b.date));
    return planners;
  }

  Future<void> _openTodoEditor({_TodoEntry? existing}) async {
    final bool isEditing = existing != null;
    final TextEditingController titleController = TextEditingController(
      text: existing?.note.title ?? '',
    );
    final TextEditingController detailsController = TextEditingController(
      text: existing?.payload.details ?? '',
    );
    bool isDone = existing?.payload.isDone ?? false;

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
                            Icons.edit_note,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isEditing ? 'Edit Task' : 'New Task',
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
                        hintText: 'What do you need to do?',
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
                    GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          isDone = !isDone;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppPalette.primarySoft
                              : AppPalette.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDone ? AppPalette.primary : Colors.black12,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isDone ? AppPalette.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDone ? AppPalette.primary : Colors.black38,
                                  width: 2,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isDone ? 'Completed' : 'Mark as completed',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDone ? AppPalette.primary : Colors.black87,
                              ),
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
                                database.removeNote(existing!.index);
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
                              final String details = detailsController.text.trim();

                              if (title.isEmpty) {
                                return;
                              }

                              final NoteData task = NoteData(
                                title: title,
                                content: _encodeTodo(details: details, isDone: isDone),
                                date: DateTime.now().toIso8601String(),
                                blockColorValue: 0xFF66BB6A,
                              );

                              if (isEditing) {
                                database.updateNote(existing!.index, task);
                              } else {
                                database.addNote(task);
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
    detailsController.dispose();
  }

  Future<void> _openTodoViewer(_TodoEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                        color: entry.payload.isDone
                            ? AppPalette.primarySoft
                            : AppPalette.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        entry.payload.isDone
                            ? Icons.check_circle
                            : Icons.pending_outlined,
                        color: entry.payload.isDone
                            ? AppPalette.primary
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        entry.note.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppPalette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.payload.isDone ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: entry.payload.isDone
                              ? AppPalette.primary
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (entry.payload.details.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.payload.details,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openTodoEditor(existing: entry);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
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
  }

  void _toggleTodoStatus(_TodoEntry entry) {
    final NoteData updated = NoteData(
      title: entry.note.title,
      content: _encodeTodo(
        details: entry.payload.details,
        isDone: !entry.payload.isDone,
      ),
      date: entry.note.date,
      blockColorValue: entry.note.blockColorValue,
    );

    database.updateNote(entry.index, updated);
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppPalette.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppPalette.textMuted.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTodoItem(_TodoEntry todo, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _openTodoViewer(todo),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: todo.payload.isDone ? AppPalette.primarySoft : AppPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black38),
            boxShadow: todo.payload.isDone
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: todo.payload.isDone,
                  onChanged: (_) => _toggleTodoStatus(todo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: todo.payload.isDone ? TextDecoration.lineThrough : null,
                        color: todo.payload.isDone ? AppPalette.textMuted : Colors.black,
                      ),
                    ),
                    if (todo.payload.details.isNotEmpty)
                      Text(
                        todo.payload.details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: todo.payload.isDone ? AppPalette.textMuted.withValues(alpha: 0.7) : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openTodoEditor(existing: todo),
                icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
              ),
              IconButton(
                onPressed: () => database.removeNote(todo.index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    final String dayName = DateFormat('EEE').format(now);
    final String dayNumber = DateFormat('d').format(now);
    final String month = DateFormat('MMMM').format(now);

    String greeting;
    final int hour = now.hour;

    if (hour < 12) {
      greeting = 'GOOD\nMORNING';
    } else if (hour < 17) {
      greeting = 'GOOD\nAFTERNOON';
    } else {
      greeting = 'GOOD\nEVENING';
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: const BottomAppBar(
        child: TaskBar(),
      ),
      body: FadeTransition(
        opacity: _greetingFade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              StudyBuddyPageTitle(
                title: greeting,
                subtitle: 'Welcome Back',
                padding: EdgeInsets.zero,
                trailing: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'profilePhoto',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        color: AppPalette.surface,
                      ),
                      child: ValueListenableBuilder<Box>(
                        valueListenable: Hive.box('profileBox').listenable(),
                        builder: (context, box, _) {
                          final Uint8List? photo =
                              _photoBytes(box.get('profilePhotoBase64') as String?);

                          if (photo == null) {
                            return const Icon(Icons.person, color: Colors.black);
                          }

                          return ClipOval(
                            child: Image.memory(
                              photo,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ValueListenableBuilder<Box>(
                valueListenable: Hive.box('focusBox').listenable(),
                builder: (context, focusBox, _) {
                  final int streak = _focusStreakDays(focusBox);
                  final int todaySeconds = _todayFocusSeconds(focusBox);
                  final int studyTarget =
                      (((focusBox.get('studyHours') as int?) ?? 0) * 3600) +
                      (((focusBox.get('studyMinutes') as int?) ?? 25) * 60) +
                      ((focusBox.get('studySeconds') as int?) ?? 0);
                  final int safeTarget = studyTarget <= 0 ? 25 * 60 : studyTarget;
                  final double ratio = (todaySeconds / safeTarget).clamp(0, 1);

                  return GestureDetector(
                    onTapDown: (_) => _cardController.reverse(),
                    onTapUp: (_) => _cardController.forward(),
                    onTapCancel: () => _cardController.forward(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlannerEmptyScreen(),
                        ),
                      );
                    },
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 214),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppPalette.primarySoft,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dayNumber,
                                      style: const TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      month.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: VerticalDivider(
                                  width: 2,
                                  thickness: 2,
                                  color: Colors.black,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          size: 16,
                                          color: AppPalette.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'FOCUS INSIGHTS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            letterSpacing: 0.8,
                                            fontWeight: FontWeight.w800,
                                            color: AppPalette.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '$streak day streak',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 8,
                                        backgroundColor: AppPalette.primarySoft,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppPalette.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(ratio * 100).round()}% of today\'s focus target',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const Divider(thickness: 1),
              const SizedBox(height: 6),
              Expanded(
                child: ValueListenableBuilder<Box<NoteData>>(
                  valueListenable: Hive.box<NoteData>('notesBox').listenable(),
                  builder: (context, notesBox, _) {
                    final List<_TodoEntry> todos = _buildTodoEntries(notesBox);
                    final List<_PlannerEntry> plannerPreview = _buildPlannerPreview(notesBox);

                    return RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(const Duration(seconds: 1));
                        setState(() {});
                      },
                      color: AppPalette.primary,
                      backgroundColor: AppPalette.surface,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TODAY TO-DO',
                                style: TextStyle(
                                  fontSize: 18,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppPalette.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () => _openTodoEditor(),
                                  icon: const Icon(Icons.add, color: AppPalette.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (todos.isEmpty)
                            _buildEmptyState('No tasks yet. Tap + to add your first task.', Icons.check_circle_outline)
                          else
                            ...todos.asMap().entries.map(
                              (entry) => _buildAnimatedTodoItem(entry.value, entry.key),
                            ),
                          const SizedBox(height: 8),
                          const Divider(thickness: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PLANNER PREVIEW',
                                style: TextStyle(
                                  fontSize: 18,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PlannerEmptyScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('Open'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (plannerPreview.isEmpty)
                            _buildEmptyState('No planner tasks due in the next 7 days.', Icons.calendar_today)
                          else
                            ...plannerPreview.take(5).map(
                              (entry) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(entry.note.blockColorValue).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.black38),
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppPalette.primarySoft,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            DateFormat('EEE, d MMM • hh:mm a').format(entry.date),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (entry.payload.location.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 14, color: Colors.black54),
                                            const SizedBox(width: 4),
                                            Text(
                                              entry.payload.location,
                                              style: const TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (entry.payload.details.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          entry.payload.details,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
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

class _TodoPayload {
  const _TodoPayload({
    required this.details,
    required this.isDone,
  });

  final String details;
  final bool isDone;
}

class _TodoEntry {
  const _TodoEntry({
    required this.index,
    required this.note,
    required this.payload,
    required this.createdAt,
  });

  final int index;
  final NoteData note;
  final _TodoPayload payload;
  final DateTime createdAt;
}

class _PlannerPayload {
  const _PlannerPayload({
    required this.location,
    required this.details,
  });

  final String location;
  final String details;
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