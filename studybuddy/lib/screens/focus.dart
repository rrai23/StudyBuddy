import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:studybuddy/shared/app_palette.dart';
import 'package:studybuddy/shared/page_title.dart';
import 'package:studybuddy/shared/taskbar.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FocusMain();
  }
}

enum FocusMode { study, breakTime }

class _FocusMain extends StatefulWidget {
  const _FocusMain();

  @override
  State<_FocusMain> createState() => _FocusMainState();
}

class _FocusMainState extends State<_FocusMain> {
  static const String _completedStatus = 'Completed';
  static const String _stoppedStatus = 'Stopped Early';

  late final Box focusBox;

  Timer? timer;
  bool isRunning = false;
  bool isPaused = false;
  bool isPhaseTransitioning = false;

  FocusMode currentMode = FocusMode.study;

  int studyHours = 0;
  int studyMinutes = 25;
  int studySeconds = 0;

  int breakHours = 0;
  int breakMinutes = 5;
  int breakSeconds = 0;

  int remainingSeconds = 25 * 60;

  int totalStudiedSeconds = 0;
  int currentStudySegmentSeconds = 0;
  int completedSessionsCount = 0;

  DateTime? activeStudySessionStartAt;

  List<Map<String, dynamic>> focusSessions = [];

  @override
  void initState() {
    super.initState();
    focusBox = Hive.box('focusBox');
    _loadSavedFocusState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _loadSavedFocusState() {
    try {
      studyHours = (focusBox.get('studyHours') as int?) ?? 0;
      studyMinutes = (focusBox.get('studyMinutes') as int?) ?? 25;
      studySeconds = (focusBox.get('studySeconds') as int?) ?? 0;

      breakHours = (focusBox.get('breakHours') as int?) ?? 0;
      breakMinutes = (focusBox.get('breakMinutes') as int?) ?? 5;
      breakSeconds = (focusBox.get('breakSeconds') as int?) ?? 0;

      totalStudiedSeconds = (focusBox.get('totalStudiedSeconds') as int?) ?? 0;
      completedSessionsCount = (focusBox.get('completedSessionsCount') as int?) ?? 0;

      focusSessions = _normalizeSessions(focusBox.get('focusSessions'));

      if (totalStudiedSeconds <= 0 && focusSessions.isNotEmpty) {
        totalStudiedSeconds = focusSessions.fold<int>(
          0,
          (sum, session) => sum + ((session['durationSeconds'] as int?) ?? 0),
        );
      }

      if (completedSessionsCount <= 0 && focusSessions.isNotEmpty) {
        completedSessionsCount = focusSessions
            .where((session) => (session['status']?.toString() ?? '') == _completedStatus)
            .length;
      }

      _updateRemainingSeconds();
    } catch (e) {
      debugPrint('Failed to load focus state: $e');
    }
  }

  List<Map<String, dynamic>> _normalizeSessions(dynamic rawSessions) {
    if (rawSessions is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];

    for (final dynamic item in rawSessions) {
      if (item is! Map) {
        continue;
      }

      final int duration = _toInt(item['durationSeconds']);
      final String start = (item['start']?.toString() ?? '').trim();
      final String end = (item['end']?.toString() ?? '').trim();
      final String status = (item['status']?.toString() ?? '').trim();

      if (duration <= 0) {
        continue;
      }

      normalized.add(
        <String, dynamic>{
          'start': start,
          'end': end,
          'durationSeconds': duration,
          'status': status.isEmpty ? _completedStatus : status,
        },
      );
    }

    normalized.sort((a, b) {
      final DateTime? endA = DateTime.tryParse(a['end']?.toString() ?? '');
      final DateTime? endB = DateTime.tryParse(b['end']?.toString() ?? '');

      if (endA == null && endB == null) {
        return 0;
      }
      if (endA == null) {
        return 1;
      }
      if (endB == null) {
        return -1;
      }

      return endB.compareTo(endA);
    });

    return normalized;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _updateRemainingSeconds() {
    if (currentMode == FocusMode.study) {
      remainingSeconds = (studyHours * 3600) + (studyMinutes * 60) + studySeconds;
    } else {
      remainingSeconds = (breakHours * 3600) + (breakMinutes * 60) + breakSeconds;
    }
  }

  void _prepareStudyMode() {
    currentMode = FocusMode.study;
    _updateRemainingSeconds();
  }

  void _prepareBreakMode() {
    currentMode = FocusMode.breakTime;
    _updateRemainingSeconds();
  }

  Future<void> _saveSettings() async {
    try {
      await focusBox.put('studyHours', studyHours);
      await focusBox.put('studyMinutes', studyMinutes);
      await focusBox.put('studySeconds', studySeconds);

      await focusBox.put('breakHours', breakHours);
      await focusBox.put('breakMinutes', breakMinutes);
      await focusBox.put('breakSeconds', breakSeconds);
    } catch (e) {
      debugPrint('Failed to save focus settings: $e');
    }
  }

  Future<void> _saveStats() async {
    try {
      await focusBox.put('totalStudiedSeconds', totalStudiedSeconds);
      await focusBox.put('focusSessions', focusSessions);
      await focusBox.put('completedSessionsCount', completedSessionsCount);
    } catch (e) {
      debugPrint('Failed to save focus stats: $e');
    }
  }

  String formatClock(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  String formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatSessionDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return '--';
    }

    try {
      final DateTime? parsed = DateTime.tryParse(isoDate);
      if (parsed == null) {
        return '--';
      }
      return DateFormat('MM/dd HH:mm').format(parsed);
    } catch (e) {
      return '--';
    }
  }

  void _showStatusMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _setCustomTimes() async {
    int tempStudyHours = studyHours;
    int tempStudyMinutes = studyMinutes;
    int tempStudySeconds = studySeconds;

    int tempBreakHours = breakHours;
    int tempBreakMinutes = breakMinutes;
    int tempBreakSeconds = breakSeconds;

    final TextEditingController studyHoursCtl = TextEditingController(text: tempStudyHours.toString());
    final TextEditingController studyMinutesCtl = TextEditingController(text: tempStudyMinutes.toString());
    final TextEditingController studySecondsCtl = TextEditingController(text: tempStudySeconds.toString());

    final TextEditingController breakHoursCtl = TextEditingController(text: tempBreakHours.toString());
    final TextEditingController breakMinutesCtl = TextEditingController(text: tempBreakMinutes.toString());
    final TextEditingController breakSecondsCtl = TextEditingController(text: tempBreakSeconds.toString());

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Custom Times'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Study Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: studyHoursCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Hours'),
                        onChanged: (value) => tempStudyHours = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: studyMinutesCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                        onChanged: (value) => tempStudyMinutes = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: studySecondsCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Seconds'),
                        onChanged: (value) => tempStudySeconds = int.tryParse(value) ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Break Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: breakHoursCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Hours'),
                        onChanged: (value) => tempBreakHours = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: breakMinutesCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                        onChanged: (value) => tempBreakMinutes = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: breakSecondsCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Seconds'),
                        onChanged: (value) => tempBreakSeconds = int.tryParse(value) ?? 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (tempStudyHours == 0 && tempStudyMinutes == 0 && tempStudySeconds == 0) {
                  _showStatusMessage('Study time must be greater than 0');
                  return;
                }
                if (tempBreakHours == 0 && tempBreakMinutes == 0 && tempBreakSeconds == 0) {
                  _showStatusMessage('Break time must be greater than 0');
                  return;
                }

                timer?.cancel();
                timer = null;

                setState(() {
                  isRunning = false;
                  isPaused = false;
                  isPhaseTransitioning = false;

                  studyHours = tempStudyHours;
                  studyMinutes = tempStudyMinutes;
                  studySeconds = tempStudySeconds;

                  breakHours = tempBreakHours;
                  breakMinutes = tempBreakMinutes;
                  breakSeconds = tempBreakSeconds;

                  _prepareStudyMode();
                  _updateRemainingSeconds();
                  currentStudySegmentSeconds = 0;
                  activeStudySessionStartAt = null;
                });

                _saveSettings();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    studyHoursCtl.dispose();
    studyMinutesCtl.dispose();
    studySecondsCtl.dispose();
    breakHoursCtl.dispose();
    breakMinutesCtl.dispose();
    breakSecondsCtl.dispose();
  }

  Future<void> _saveCompletedStudySession({required String status}) async {
    if (currentStudySegmentSeconds <= 0 && activeStudySessionStartAt == null) {
      return;
    }

    try {
      final DateTime endTime = DateTime.now();
      final DateTime startTime = activeStudySessionStartAt ?? endTime.subtract(Duration(seconds: currentStudySegmentSeconds));
      final int duration = currentStudySegmentSeconds > 0
          ? currentStudySegmentSeconds
          : endTime.difference(startTime).inSeconds;

      if (duration <= 0) {
        currentStudySegmentSeconds = 0;
        activeStudySessionStartAt = null;
        return;
      }

      totalStudiedSeconds += duration;
      if (status == _completedStatus) {
        completedSessionsCount += 1;
      }

      focusSessions.insert(0, {
        'start': startTime.toIso8601String(),
        'end': endTime.toIso8601String(),
        'durationSeconds': duration,
        'status': status,
      });

      if (focusSessions.length > 200) {
        focusSessions = focusSessions.sublist(0, 200);
      }

      currentStudySegmentSeconds = 0;
      activeStudySessionStartAt = null;

      await _saveStats();
      _showStatusMessage('Session saved successfully ✓');
    } catch (e) {
      _showStatusMessage('Error saving session');
    }
  }

  int _getTodayTotalSeconds() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    int total = 0;
    for (final session in focusSessions) {
      try {
        final DateTime? end = DateTime.tryParse(session['end']?.toString() ?? '');
        if (end == null) continue;

        final DateTime endDay = DateTime(end.year, end.month, end.day);
        if (endDay == today) {
          total += (session['durationSeconds'] as int?) ?? 0;
        }
      } catch (e) {
        continue;
      }
    }

    return total;
  }

  int _getWeeklyTotalSeconds() {
    final DateTime now = DateTime.now();
    final DateTime weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    int total = 0;
    for (final session in focusSessions) {
      try {
        final DateTime? end = DateTime.tryParse(session['end']?.toString() ?? '');
        if (end == null) continue;

        if (!end.isBefore(weekStart)) {
          total += (session['durationSeconds'] as int?) ?? 0;
        }
      } catch (e) {
        continue;
      }
    }

    return total;
  }

  void startTimer() {
    if (isRunning || isPhaseTransitioning) {
      return;
    }

    if (remainingSeconds <= 0) {
      _updateRemainingSeconds();
    }

    if (currentMode == FocusMode.study && activeStudySessionStartAt == null) {
      activeStudySessionStartAt = DateTime.now();
    }

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isPhaseTransitioning || !isRunning) {
        return;
      }

      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;

          if (currentMode == FocusMode.study) {
            currentStudySegmentSeconds++;
          }
        }
      });

      if (remainingSeconds <= 0 && !isPhaseTransitioning) {
        _handlePhaseFinished();
      }
    });

    setState(() {
      isRunning = true;
      isPaused = false;
    });

    if (currentMode == FocusMode.study) {
      _showStatusMessage('Focus started');
    } else {
      _showStatusMessage('Break started');
    }
  }

  void startBreakTimer() {
    if (isPhaseTransitioning) {
      return;
    }

    if (isRunning) {
      pauseTimer();
    }

    setState(() {
      _prepareBreakMode();
      currentStudySegmentSeconds = 0;
      activeStudySessionStartAt = null;
    });

    startTimer();
  }

  void startStudyTimer() {
    if (isRunning || isPhaseTransitioning) {
      return;
    }

    setState(() {
      _prepareStudyMode();
      currentStudySegmentSeconds = 0;
      activeStudySessionStartAt = null;
    });

    startTimer();
  }

  String _primaryButtonLabel() {
    if (isPaused) {
      return currentMode == FocusMode.study ? 'Resume Focus' : 'Resume Break';
    }

    return currentMode == FocusMode.study ? 'Let\'s Focus!' : 'Start Break';
  }

  String _secondaryButtonLabel() {
    return currentMode == FocusMode.study ? 'Start Break' : 'Start Focus';
  }

  VoidCallback _secondaryButtonAction() {
    return currentMode == FocusMode.study ? startBreakTimer : startStudyTimer;
  }

  void pauseTimer() {
    if (!isRunning) {
      return;
    }

    timer?.cancel();
    timer = null;

    setState(() {
      isRunning = false;
      isPaused = true;
    });

    _showStatusMessage('Timer paused');
  }

  Future<void> _handlePhaseFinished() async {
    if (isPhaseTransitioning) {
      return;
    }

    isPhaseTransitioning = true;
    timer?.cancel();
    timer = null;
    bool shouldAutoStartNext = false;

    if (mounted) {
      setState(() {
        isRunning = false;
        isPaused = false;
      });
    }

    try {
      if (currentMode == FocusMode.study) {
        await _saveCompletedStudySession(status: _completedStatus);

        if (!mounted) {
          return;
        }

        setState(() {
          currentMode = FocusMode.breakTime;
          _updateRemainingSeconds();
          activeStudySessionStartAt = null;
          currentStudySegmentSeconds = 0;
        });

        _showStatusMessage('Session complete! Taking a break now');
        unawaited(_showBreakPopup());

        await Future.delayed(const Duration(milliseconds: 500));

        shouldAutoStartNext = true;
        return;
      }

      if (currentMode == FocusMode.breakTime) {
        if (!mounted) {
          return;
        }

        setState(() {
          currentMode = FocusMode.study;
          _updateRemainingSeconds();
          activeStudySessionStartAt = null;
          currentStudySegmentSeconds = 0;
        });

        _showStatusMessage('Break complete! Back to focus');

        await Future.delayed(const Duration(milliseconds: 500));

        shouldAutoStartNext = true;
      }
    } catch (e) {
      _showStatusMessage('Error occurred');  
    } finally {
      isPhaseTransitioning = false;

      if (shouldAutoStartNext && mounted) {
        startTimer();
      }
    }
  }

  Future<void> _showBreakPopup() async {
    if (!mounted) return;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          Timer(const Duration(seconds: 2), () {
            final NavigatorState navigator = Navigator.of(dialogContext);
            if (navigator.mounted && navigator.canPop()) {
              navigator.pop();
            }
          });

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Break Time!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'lib/assets/break.gif',
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.orange.shade100,
                          child: const Center(
                            child: Text('Break Time!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Failed to show break popup: $e');
    }
  }

  Future<void> stopTimer() async {
    timer?.cancel();
    timer = null;

    final bool shouldSavePartialStudy =
        currentMode == FocusMode.study &&
        (currentStudySegmentSeconds > 0 || activeStudySessionStartAt != null);

    if (shouldSavePartialStudy) {
      await _saveCompletedStudySession(status: _stoppedStatus);
    }

    setState(() {
      isRunning = false;
      isPaused = false;
      isPhaseTransitioning = false;
      _prepareStudyMode();
      _updateRemainingSeconds();
      currentStudySegmentSeconds = 0;
      activeStudySessionStartAt = null;
    });

    _showStatusMessage('Timer stopped');
  }

  Future<void> resetTimer() async {
    timer?.cancel();
    timer = null;

    setState(() {
      isRunning = false;
      isPaused = false;
      isPhaseTransitioning = false;
      _prepareStudyMode();
      _updateRemainingSeconds();
      currentStudySegmentSeconds = 0;
      activeStudySessionStartAt = null;
    });

    _showStatusMessage('Timer reset');
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 110, maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int todaySeconds = _getTodayTotalSeconds();
    final int weekSeconds = _getWeeklyTotalSeconds();
    final bool isFocusedMode = isRunning && currentMode == FocusMode.study;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const BottomAppBar(
        child: TaskBar(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const StudyBuddyPageTitle(
                title: 'THE\nFOCUS',
                subtitle: 'Deep Work Mode',
              ),
              const SizedBox(height: 20),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: currentMode == FocusMode.study
                        ? AppPalette.primarySoft
                        : AppPalette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    currentMode == FocusMode.study ? 'Study Time' : 'Break Time',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      formatClock(remainingSeconds),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: currentMode == FocusMode.study
                            ? AppPalette.primary
                            : AppPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Study ${studyHours > 0 ? '${studyHours}h ' : ''}${studyMinutes}m ${studySeconds}s  |  Break ${breakHours > 0 ? '${breakHours}h ' : ''}${breakMinutes}m ${breakSeconds}s',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    height: isFocusedMode ? 320 : 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'lib/assets/animation.gif',
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: isFocusedMode ? 320 : 280,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Text('Animation')),
                                );
                              },
                            ),
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: 0,
                            child: Container(color: Colors.black),
                          ),
                          if (isFocusedMode)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Focused Mode ON',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: _buildButton('Set Times', _setCustomTimes),
              ),
              const SizedBox(height: 14),
              Center(
                child: isRunning
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildButton('Pause', pauseTimer),
                          _buildButton('Stop', stopTimer),
                          _buildButton('Reset', resetTimer),
                        ],
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildButton(_primaryButtonLabel(), startTimer),
                          _buildButton(_secondaryButtonLabel(), _secondaryButtonAction()),
                          if (isPaused) ...[
                            _buildButton('Stop', stopTimer),
                            _buildButton('Reset', resetTimer),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Total Studied: ${formatDuration(totalStudiedSeconds)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSummaryCard('Today', formatDuration(todaySeconds)),
                    const SizedBox(width: 8),
                    _buildSummaryCard('This Week', formatDuration(weekSeconds)),
                    const SizedBox(width: 8),
                    _buildSummaryCard('Sessions', '$completedSessionsCount'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Session History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              if (focusSessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('No completed focus sessions yet. Start studying!'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: focusSessions.length > 8 ? 8 : focusSessions.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> session = focusSessions[index];
                    final int duration = (session['durationSeconds'] as int?) ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration: ${formatDuration(duration)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${(session['status']?.toString() ?? _completedStatus)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start: ${_formatSessionDate(session['start']?.toString())}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'End: ${_formatSessionDate(session['end']?.toString())}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
