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

  static const String _keyIsRunning = 'isRunning';
  static const String _keyIsPaused = 'isPaused';
  static const String _keyCurrentMode = 'currentMode';
  static const String _keyRemainingSeconds = 'remainingSeconds';
  static const String _keyCurrentStudySegmentSeconds = 'currentStudySegmentSeconds';
  static const String _keyActiveStudySessionStartAt = 'activeStudySessionStartAt';
  static const String _keySessionStateSavedAt = 'sessionStateSavedAt';

  late final Box focusBox;

  Timer? timer;
  bool isRunning = false;
  bool isPaused = false;
  bool isPhaseTransitioning = false;

  bool _isBreakDialogShowing = false;

  int _controlVersion = 0;

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
    _saveSessionState();
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

      // Restore mode first (so defaults are computed correctly).
      final String? modeStr = focusBox.get(_keyCurrentMode) as String?;
      if (modeStr == 'FocusMode.breakTime') {
        currentMode = FocusMode.breakTime;
      } else {
        currentMode = FocusMode.study;
      }

      // Establish a baseline (full duration) before applying any restored running state.
      _updateRemainingSeconds();

      // Restore active session state if one was running
      _restoreActiveSessionState();
    } catch (e) {
      debugPrint('Failed to load focus state: $e');
    }
  }

  void _restoreActiveSessionState() {
    try {
      final bool wasRunning = (focusBox.get(_keyIsRunning) as bool?) ?? false;
      final bool wasPaused = (focusBox.get(_keyIsPaused) as bool?) ?? false;

      // If it wasn't running, there's nothing to restore.
      if (!wasRunning) {
        isRunning = false;
        isPaused = wasPaused;
        return;
      }

      final int savedRemaining = (focusBox.get(_keyRemainingSeconds) as int?) ?? remainingSeconds;
      final int savedStudySegmentSeconds = (focusBox.get(_keyCurrentStudySegmentSeconds) as int?) ?? 0;
      final String? savedAtIso = focusBox.get(_keySessionStateSavedAt) as String?;

      // Restore active study session start time (used only for history metadata).
      final String? sessionStartIso = focusBox.get(_keyActiveStudySessionStartAt) as String?;
      if (sessionStartIso != null && sessionStartIso.isNotEmpty) {
        activeStudySessionStartAt = DateTime.tryParse(sessionStartIso);
      }

      int deltaSeconds = 0;
      if (savedAtIso != null && savedAtIso.isNotEmpty) {
        final DateTime? savedAt = DateTime.tryParse(savedAtIso);
        if (savedAt != null) {
          deltaSeconds = DateTime.now().difference(savedAt).inSeconds;
          if (deltaSeconds < 0) {
            deltaSeconds = 0;
          }
        }
      }

      // If it was paused, don't advance time while away.
      if (wasPaused) {
        isRunning = false;
        isPaused = true;
        remainingSeconds = savedRemaining;
        currentStudySegmentSeconds = savedStudySegmentSeconds;
        return;
      }

      final int advanced = deltaSeconds.clamp(0, savedRemaining);
      remainingSeconds = (savedRemaining - deltaSeconds).clamp(0, savedRemaining);

      if (currentMode == FocusMode.study) {
        currentStudySegmentSeconds = savedStudySegmentSeconds + advanced;
      } else {
        currentStudySegmentSeconds = savedStudySegmentSeconds;
      }

      // Keep the session logically running, but resume the UI ticker silently.
      isRunning = remainingSeconds > 0;
      isPaused = false;

      if (isRunning) {
        _startTickerSilently();
      }
    } catch (e) {
      debugPrint('Failed to restore active session state: $e');
    }
  }

  void _startTickerSilently() {
    if (timer != null) {
      return;
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

  Future<void> _saveSessionState() async {
    try {
      await focusBox.put(_keyIsRunning, isRunning);
      await focusBox.put(_keyIsPaused, isPaused);
      await focusBox.put(_keyCurrentMode, currentMode.toString());
      await focusBox.put(_keyRemainingSeconds, remainingSeconds);
      await focusBox.put(_keyCurrentStudySegmentSeconds, currentStudySegmentSeconds);
      await focusBox.put(
        _keyActiveStudySessionStartAt,
        activeStudySessionStartAt?.toIso8601String() ?? '',
      );
      await focusBox.put(_keySessionStateSavedAt, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to save session state: $e');
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
                _clearSessionState();
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

  Future<void> _saveCompletedStudySession({
    required String status,
    DateTime? startAtOverride,
    int? durationSecondsOverride,
  }) async {
    final int effectiveSegmentSeconds = durationSecondsOverride ?? currentStudySegmentSeconds;
    final DateTime? effectiveStartAt = startAtOverride ?? activeStudySessionStartAt;

    if (effectiveSegmentSeconds <= 0 && effectiveStartAt == null) {
      return;
    }

    try {
      final DateTime endTime = DateTime.now();
      final DateTime startTime = effectiveStartAt ?? endTime.subtract(Duration(seconds: effectiveSegmentSeconds));
      final int duration = effectiveSegmentSeconds > 0
          ? effectiveSegmentSeconds
          : endTime.difference(startTime).inSeconds;

      if (duration <= 0) {
        currentStudySegmentSeconds = 0;
        activeStudySessionStartAt = null;
        await _clearSessionState();
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
      await _clearSessionState();
      _showStatusMessage('Session saved successfully ✓');
    } catch (e) {
      _showStatusMessage('Error saving session');
    }
  }

  Future<void> _clearSessionState() async {
    try {
      await focusBox.delete(_keyIsRunning);
      await focusBox.delete(_keyIsPaused);
      await focusBox.delete(_keyCurrentMode);
      await focusBox.delete(_keyRemainingSeconds);
      await focusBox.delete(_keyCurrentStudySegmentSeconds);
      await focusBox.delete(_keyActiveStudySessionStartAt);
      await focusBox.delete(_keySessionStateSavedAt);
    } catch (e) {
      debugPrint('Failed to clear session state: $e');
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

    setState(() {
      isRunning = true;
      isPaused = false;
    });

    // Persist state at the moment we start/resume so we can advance correctly while off-page.
    _saveSessionState();

    _startTickerSilently();

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

    _controlVersion++;

    timer?.cancel();
    timer = null;

    setState(() {
      isRunning = false;
      isPaused = true;
    });

    _saveSessionState();
    _showStatusMessage('Timer paused');
  }

  Future<void> _handlePhaseFinished() async {
    if (isPhaseTransitioning) {
      return;
    }

    final int versionAtStart = _controlVersion;

    isPhaseTransitioning = true;
    timer?.cancel();
    timer = null;
    bool shouldAutoStartNext = false;

    if (mounted) {
      setState(() {
        isRunning = false;
        isPaused = false;
      });
      await _saveSessionState();
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

        await _saveSessionState();
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

        await _saveSessionState();
        _showStatusMessage('Break complete! Back to focus');

        await Future.delayed(const Duration(milliseconds: 500));

        shouldAutoStartNext = true;
      }
    } catch (e) {
      _showStatusMessage('Error occurred');
    } finally {
      isPhaseTransitioning = false;

      if (shouldAutoStartNext && mounted && _controlVersion == versionAtStart) {
        startTimer();
      }
    }
  }

  Future<void> _showBreakPopup() async {
    if (!mounted) return;

    if (_isBreakDialogShowing) {
      return;
    }

    _isBreakDialogShowing = true;
    bool scheduledAutoClose = false;

    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (dialogContext) {
          if (!scheduledAutoClose) {
            scheduledAutoClose = true;
            final NavigatorState navigator = Navigator.of(
              dialogContext,
              rootNavigator: true,
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (navigator.mounted && navigator.canPop()) {
                navigator.pop();
              }
            });
          }

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
    } finally {
      _isBreakDialogShowing = false;
    }
  }

  Future<void> stopTimer() async {
    timer?.cancel();
    timer = null;

    // Cancels any pending auto-start (e.g., from phase transitions).
    _controlVersion++;

    // Capture current session values first (we reset state before awaiting).
    final FocusMode modeBeforeStop = currentMode;
    final DateTime? startBeforeStop = activeStudySessionStartAt;
    final int segmentSecondsBeforeStop = currentStudySegmentSeconds;
    final bool shouldSavePartialStudy =
        modeBeforeStop == FocusMode.study &&
        (segmentSecondsBeforeStop > 0 || startBeforeStop != null);

    if (mounted) {
      setState(() {
        isRunning = false;
        isPaused = false;
        isPhaseTransitioning = false;
        _prepareStudyMode();
        _updateRemainingSeconds();
        currentStudySegmentSeconds = 0;
        activeStudySessionStartAt = null;
      });
    } else {
      isRunning = false;
      isPaused = false;
      isPhaseTransitioning = false;
      _prepareStudyMode();
      _updateRemainingSeconds();
      currentStudySegmentSeconds = 0;
      activeStudySessionStartAt = null;
    }

    // Ensure returning to this page will NOT resume a stopped session.
    await _clearSessionState();

    if (shouldSavePartialStudy) {
      await _saveCompletedStudySession(
        status: _stoppedStatus,
        startAtOverride: startBeforeStop,
        durationSecondsOverride: segmentSecondsBeforeStop,
      );
    }

    _showStatusMessage('Timer stopped');
  }

  Future<void> resetTimer() async {
    timer?.cancel();
    timer = null;

    // Cancels any pending auto-start (e.g., from phase transitions).
    _controlVersion++;

    if (mounted) {
      setState(() {
        isRunning = false;
        isPaused = false;
        isPhaseTransitioning = false;
        _prepareStudyMode();
        _updateRemainingSeconds();
        currentStudySegmentSeconds = 0;
        activeStudySessionStartAt = null;
      });
    } else {
      isRunning = false;
      isPaused = false;
      isPhaseTransitioning = false;
      _prepareStudyMode();
      _updateRemainingSeconds();
      currentStudySegmentSeconds = 0;
      activeStudySessionStartAt = null;
    }

    // Ensure returning to this page will NOT resume a reset session.
    await _clearSessionState();
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
