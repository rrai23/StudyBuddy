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

class _FocusMainState extends State<_FocusMain> with TickerProviderStateMixin {
  static const String _completedStatus = 'Completed';
  static const String _stoppedStatus = 'Stopped Early';

  late final Box focusBox;

  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isPhaseTransitioning = false;

  FocusMode _currentMode = FocusMode.study;

  int _studyHours = 0;
  int _studyMinutes = 25;
  int _studySeconds = 0;

  int _breakHours = 0;
  int _breakMinutes = 5;
  int _breakSeconds = 0;

  int _remainingSeconds = 25 * 60;

  int _totalStudiedSeconds = 0;
  int _currentStudySegmentSeconds = 0;
  int _completedSessionsCount = 0;

  DateTime? _activeStudySessionStartAt;

  List<Map<String, dynamic>> _focusSessions = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    focusBox = Hive.box('focusBox');
    _loadSavedFocusState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadSavedFocusState() {
    try {
      _studyHours = (focusBox.get('studyHours') as int?) ?? 0;
      _studyMinutes = (focusBox.get('studyMinutes') as int?) ?? 25;
      _studySeconds = (focusBox.get('studySeconds') as int?) ?? 0;

      _breakHours = (focusBox.get('breakHours') as int?) ?? 0;
      _breakMinutes = (focusBox.get('breakMinutes') as int?) ?? 5;
      _breakSeconds = (focusBox.get('breakSeconds') as int?) ?? 0;

      _totalStudiedSeconds = (focusBox.get('totalStudiedSeconds') as int?) ?? 0;
      _completedSessionsCount = (focusBox.get('completedSessionsCount') as int?) ?? 0;

      _focusSessions = _normalizeSessions(focusBox.get('focusSessions'));

      if (_totalStudiedSeconds <= 0 && _focusSessions.isNotEmpty) {
        _totalStudiedSeconds = _focusSessions.fold<int>(
          0,
          (sum, session) => sum + ((session['durationSeconds'] as int?) ?? 0),
        );
      }

      if (_completedSessionsCount <= 0 && _focusSessions.isNotEmpty) {
        _completedSessionsCount = _focusSessions
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
    if (_currentMode == FocusMode.study) {
      _remainingSeconds = (_studyHours * 3600) + (_studyMinutes * 60) + _studySeconds;
    } else {
      _remainingSeconds = (_breakHours * 3600) + (_breakMinutes * 60) + _breakSeconds;
    }
  }

  void _prepareStudyMode() {
    _currentMode = FocusMode.study;
    _updateRemainingSeconds();
  }

  void _prepareBreakMode() {
    _currentMode = FocusMode.breakTime;
    _updateRemainingSeconds();
  }

  Future<void> _saveSettings() async {
    try {
      await focusBox.put('studyHours', _studyHours);
      await focusBox.put('studyMinutes', _studyMinutes);
      await focusBox.put('studySeconds', _studySeconds);

      await focusBox.put('breakHours', _breakHours);
      await focusBox.put('breakMinutes', _breakMinutes);
      await focusBox.put('breakSeconds', _breakSeconds);
    } catch (e) {
      debugPrint('Failed to save focus settings: $e');
    }
  }

  Future<void> _saveStats() async {
    try {
      await focusBox.put('totalStudiedSeconds', _totalStudiedSeconds);
      await focusBox.put('focusSessions', _focusSessions);
      await focusBox.put('completedSessionsCount', _completedSessionsCount);
    } catch (e) {
      debugPrint('Failed to save focus stats: $e');
    }
  }

  String _formatClock(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  String _formatDuration(int totalSeconds) {
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
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.black87,
        ),
      );
  }

  Widget _buildTimeField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final TextEditingController controller = TextEditingController(text: value.toString());

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppPalette.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (val) => onChanged(int.tryParse(val) ?? 0),
          ),
        ],
      ),
    );
  }

  Future<void> _setCustomTimes() async {
    if (_isRunning || _isPaused) {
      _showStatusMessage('Stop the timer first to change times');
      return;
    }

    int tempStudyHours = _studyHours;
    int tempStudyMinutes = _studyMinutes;
    int tempStudySeconds = _studySeconds;

    int tempBreakHours = _breakHours;
    int tempBreakMinutes = _breakMinutes;
    int tempBreakSeconds = _breakSeconds;

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
                            Icons.timer,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Set Custom Times',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppPalette.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 18,
                            color: AppPalette.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'STUDY TIME',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: AppPalette.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTimeField(
                          label: 'HOURS',
                          value: tempStudyHours,
                          onChanged: (val) => tempStudyHours = val.clamp(0, 23),
                        ),
                        const SizedBox(width: 12),
                        _buildTimeField(
                          label: 'MINUTES',
                          value: tempStudyMinutes,
                          onChanged: (val) => tempStudyMinutes = val.clamp(0, 59),
                        ),
                        const SizedBox(width: 12),
                        _buildTimeField(
                          label: 'SECONDS',
                          value: tempStudySeconds,
                          onChanged: (val) => tempStudySeconds = val.clamp(0, 59),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppPalette.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.coffee,
                            size: 18,
                            color: AppPalette.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'BREAK TIME',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTimeField(
                          label: 'HOURS',
                          value: tempBreakHours,
                          onChanged: (val) => tempBreakHours = val.clamp(0, 23),
                        ),
                        const SizedBox(width: 12),
                        _buildTimeField(
                          label: 'MINUTES',
                          value: tempBreakMinutes,
                          onChanged: (val) => tempBreakMinutes = val.clamp(0, 59),
                        ),
                        const SizedBox(width: 12),
                        _buildTimeField(
                          label: 'SECONDS',
                          value: tempBreakSeconds,
                          onChanged: (val) => tempBreakSeconds = val.clamp(0, 59),
                        ),
                      ],
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
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () {
                              final int totalStudySeconds = (tempStudyHours * 3600) + (tempStudyMinutes * 60) + tempStudySeconds;
                              final int totalBreakSeconds = (tempBreakHours * 3600) + (tempBreakMinutes * 60) + tempBreakSeconds;

                              if (totalStudySeconds <= 0) {
                                _showStatusMessage('Study time must be greater than 0');
                                return;
                              }
                              if (totalBreakSeconds <= 0) {
                                _showStatusMessage('Break time must be greater than 0');
                                return;
                              }

                              setState(() {
                                _studyHours = tempStudyHours;
                                _studyMinutes = tempStudyMinutes;
                                _studySeconds = tempStudySeconds;

                                _breakHours = tempBreakHours;
                                _breakMinutes = tempBreakMinutes;
                                _breakSeconds = tempBreakSeconds;

                                _prepareStudyMode();
                                _currentStudySegmentSeconds = 0;
                                _activeStudySessionStartAt = null;
                              });

                              _saveSettings();
                              Navigator.pop(context);
                              _showStatusMessage('Times updated successfully');
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save Times'),
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
  }

  Future<void> _saveCompletedStudySession({required String status}) async {
    if (_currentStudySegmentSeconds <= 0 && _activeStudySessionStartAt == null) {
      return;
    }

    try {
      final DateTime endTime = DateTime.now();
      final DateTime startTime = _activeStudySessionStartAt ?? endTime.subtract(Duration(seconds: _currentStudySegmentSeconds));
      final int duration = _currentStudySegmentSeconds > 0
          ? _currentStudySegmentSeconds
          : endTime.difference(startTime).inSeconds;

      if (duration <= 0) {
        _currentStudySegmentSeconds = 0;
        _activeStudySessionStartAt = null;
        return;
      }

      _totalStudiedSeconds += duration;
      if (status == _completedStatus) {
        _completedSessionsCount += 1;
      }

      _focusSessions.insert(0, {
        'start': startTime.toIso8601String(),
        'end': endTime.toIso8601String(),
        'durationSeconds': duration,
        'status': status,
      });

      if (_focusSessions.length > 200) {
        _focusSessions = _focusSessions.sublist(0, 200);
      }

      _currentStudySegmentSeconds = 0;
      _activeStudySessionStartAt = null;

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
    for (final session in _focusSessions) {
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
    for (final session in _focusSessions) {
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

  void _startTimer() {
    if (_isRunning || _isPhaseTransitioning) {
      return;
    }

    if (_remainingSeconds <= 0) {
      _updateRemainingSeconds();
    }

    if (_currentMode == FocusMode.study && _activeStudySessionStartAt == null) {
      _activeStudySessionStartAt = DateTime.now();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPhaseTransitioning || !_isRunning || !mounted) {
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          if (_currentMode == FocusMode.study) {
            _currentStudySegmentSeconds++;
          }
        }
      });

      if (_remainingSeconds <= 0 && !_isPhaseTransitioning && mounted) {
        _handlePhaseFinished();
      }
    });

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _showStatusMessage(_currentMode == FocusMode.study ? 'Focus started' : 'Break started');
  }

  void _startBreakTimer() {
    if (_isPhaseTransitioning) {
      return;
    }

    if (_isRunning) {
      _pauseTimer();
    }

    setState(() {
      _prepareBreakMode();
      _currentStudySegmentSeconds = 0;
      _activeStudySessionStartAt = null;
    });

    _startTimer();
  }

  void _startStudyTimer() {
    if (_isRunning || _isPhaseTransitioning) {
      return;
    }

    setState(() {
      _prepareStudyMode();
      _currentStudySegmentSeconds = 0;
      _activeStudySessionStartAt = null;
    });

    _startTimer();
  }

  String _primaryButtonLabel() {
    if (_isPaused) {
      return _currentMode == FocusMode.study ? 'Resume Focus' : 'Resume Break';
    }
    return _currentMode == FocusMode.study ? 'Let\'s Focus!' : 'Start Break';
  }

  String _secondaryButtonLabel() {
    return _currentMode == FocusMode.study ? 'Start Break' : 'Start Focus';
  }

  VoidCallback _secondaryButtonAction() {
    return _currentMode == FocusMode.study ? _startBreakTimer : _startStudyTimer;
  }

  void _pauseTimer() {
    if (!_isRunning) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _isPaused = true;
    });

    _showStatusMessage('Timer paused');
  }

  Future<void> _handlePhaseFinished() async {
    if (_isPhaseTransitioning) {
      return;
    }

    setState(() {
      _isPhaseTransitioning = true;
    });

    _timer?.cancel();
    _timer = null;

    bool shouldAutoStartNext = false;

    try {
      if (_currentMode == FocusMode.study) {
        await _saveCompletedStudySession(status: _completedStatus);

        if (!mounted) {
          return;
        }

        setState(() {
          _currentMode = FocusMode.breakTime;
          _updateRemainingSeconds();
          _activeStudySessionStartAt = null;
          _currentStudySegmentSeconds = 0;
          _isRunning = false;
          _isPaused = false;
        });

        _showStatusMessage('Session complete! Taking a break');
        await _showBreakPopup();

        await Future.delayed(const Duration(seconds: 1));
        shouldAutoStartNext = true;
      } else if (_currentMode == FocusMode.breakTime) {
        if (!mounted) {
          return;
        }

        setState(() {
          _currentMode = FocusMode.study;
          _updateRemainingSeconds();
          _activeStudySessionStartAt = null;
          _currentStudySegmentSeconds = 0;
          _isRunning = false;
          _isPaused = false;
        });

        _showStatusMessage('Break complete! Back to focus');

        await Future.delayed(const Duration(seconds: 1));
        shouldAutoStartNext = true;
      }
    } catch (e) {
      _showStatusMessage('Error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isPhaseTransitioning = false;
        });
      }

      if (shouldAutoStartNext && mounted) {
        _startTimer();
      }
    }
  }

  Future<void> _showBreakPopup() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.coffee,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Break Time!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great work! Take a ${_breakMinutes}m break.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'lib/assets/break.gif',
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            '☕ Break Time!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _stopTimer() async {
    _timer?.cancel();
    _timer = null;

    final bool shouldSavePartialStudy =
        _currentMode == FocusMode.study &&
        (_currentStudySegmentSeconds > 0 || _activeStudySessionStartAt != null);

    if (shouldSavePartialStudy) {
      await _saveCompletedStudySession(status: _stoppedStatus);
    }

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isPhaseTransitioning = false;
      _prepareStudyMode();
      _updateRemainingSeconds();
      _currentStudySegmentSeconds = 0;
      _activeStudySessionStartAt = null;
    });

    _showStatusMessage('Timer stopped');
  }

  Future<void> _resetTimer() async {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isPhaseTransitioning = false;
      _prepareStudyMode();
      _updateRemainingSeconds();
      _currentStudySegmentSeconds = 0;
      _activeStudySessionStartAt = null;
    });

    _showStatusMessage('Timer reset');
  }

  Widget _buildButton(String text, VoidCallback onTap, {Color? color, bool isPrimary = false}) {
    return GestureDetector(
      onTap: _isPhaseTransitioning ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppPalette.primary : (color ?? Colors.white),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isPrimary ? AppPalette.primary : Colors.black,
            width: 2,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppPalette.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isPrimary ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 40,
            color: AppPalette.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No completed focus sessions yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppPalette.textMuted.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start studying to see your progress!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppPalette.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int todaySeconds = _getTodayTotalSeconds();
    final int weekSeconds = _getWeeklyTotalSeconds();
    final bool isFocusedMode = _isRunning && _currentMode == FocusMode.study;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const BottomAppBar(
        child: TaskBar(),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _currentMode == FocusMode.study
                          ? AppPalette.primarySoft
                          : AppPalette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _currentMode == FocusMode.study
                            ? AppPalette.primary
                            : Colors.black12,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentMode == FocusMode.study
                              ? Icons.local_fire_department
                              : Icons.coffee,
                          size: 20,
                          color: _currentMode == FocusMode.study
                              ? AppPalette.primary
                              : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentMode == FocusMode.study ? 'Study Time' : 'Break Time',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _currentMode == FocusMode.study
                                ? AppPalette.primary
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ScaleTransition(
                    scale: _isRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppPalette.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _isRunning ? AppPalette.primary : Colors.black,
                          width: _isRunning ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isRunning
                                ? AppPalette.primary.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: _isRunning ? 24 : 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _formatClock(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: _isRunning
                                ? AppPalette.primary
                                : (_currentMode == FocusMode.study
                                    ? AppPalette.primary
                                    : Colors.black87),
                            letterSpacing: 2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppPalette.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Study ${_studyHours > 0 ? '${_studyHours}h ' : ''}${_studyMinutes}m ${_studySeconds}s  |  Break ${_breakHours > 0 ? '${_breakHours}h ' : ''}${_breakMinutes}m ${_breakSeconds}s',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: double.infinity,
                      height: isFocusedMode ? 300 : 260,
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
                                    height: isFocusedMode ? 300 : 260,
                                    decoration: BoxDecoration(
                                      color: _isRunning
                                          ? AppPalette.primarySoft
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.local_fire_department,
                                        size: 64,
                                        color: _isRunning
                                            ? AppPalette.primary.withValues(alpha: 0.4)
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (isFocusedMode)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Focused Mode ON',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: _buildButton('Set Times', _setCustomTimes),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _isPhaseTransitioning
                      ? const CircularProgressIndicator()
                      : (_isRunning
                          ? Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildButton('Pause', _pauseTimer),
                                _buildButton('Stop', _stopTimer),
                                _buildButton('Reset', _resetTimer),
                              ],
                            )
                          : Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildButton(
                                  _primaryButtonLabel(),
                                  _startTimer,
                                  isPrimary: true,
                                ),
                                _buildButton(_secondaryButtonLabel(), _secondaryButtonAction()),
                                if (_isPaused) ...[
                                  _buildButton('Stop', _stopTimer),
                                  _buildButton('Reset', _resetTimer),
                                ],
                              ],
                            )),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppPalette.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Total Studied: ${_formatDuration(_totalStudiedSeconds)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildSummaryCard('Today', _formatDuration(todaySeconds)),
                      const SizedBox(width: 10),
                      _buildSummaryCard('This Week', _formatDuration(weekSeconds)),
                      const SizedBox(width: 10),
                      _buildSummaryCard('Sessions', '$_completedSessionsCount'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppPalette.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Session History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_focusSessions.isEmpty)
                  _buildEmptyState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _focusSessions.length > 10 ? 10 : _focusSessions.length,
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> session = _focusSessions[index];
                      final int duration = (session['durationSeconds'] as int?) ?? 0;
                      final String status = session['status']?.toString() ?? _completedStatus;
                      final bool isCompleted = status == _completedStatus;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppPalette.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted ? Colors.black12 : Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isCompleted ? AppPalette.primary : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppPalette.primarySoft
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isCompleted ? AppPalette.primary : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: AppPalette.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_formatSessionDate(session['start']?.toString())} - ${_formatSessionDate(session['end']?.toString())}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppPalette.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}