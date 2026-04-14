import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
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
  late final Box focusBox;

  Timer? timer;
  bool isRunning = false;

  FocusMode currentMode = FocusMode.study;

  int studyMinutes = 25;
  int breakMinutes = 5;
  int remainingSeconds = 25 * 60;

  int totalStudiedSeconds = 0;
  int currentStudySegmentSeconds = 0;

  List<Map<String, dynamic>> studyLogs = [];

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
    studyMinutes = (focusBox.get('studyMinutes') as int?) ?? 25;
    breakMinutes = (focusBox.get('breakMinutes') as int?) ?? 5;
    totalStudiedSeconds = (focusBox.get('totalStudiedSeconds') as int?) ?? 0;

    final List<dynamic> rawLogs =
        (focusBox.get('studyLogs') as List<dynamic>?) ?? [];

    studyLogs = rawLogs
        .whereType<Map>()
        .map((entry) => {
              'date': entry['date']?.toString() ?? '',
              'seconds': (entry['seconds'] as int?) ?? 0,
            })
        .toList();

    remainingSeconds = studyMinutes * 60;
  }

  Future<void> _saveSettings() async {
    await focusBox.put('studyMinutes', studyMinutes);
    await focusBox.put('breakMinutes', breakMinutes);
  }

  Future<void> _saveStats() async {
    await focusBox.put('totalStudiedSeconds', totalStudiedSeconds);
    await focusBox.put('studyLogs', studyLogs);
  }

  String formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  Future<void> _setCustomTimes() async {
    final studyController =
        TextEditingController(text: studyMinutes.toString());
    final breakController =
        TextEditingController(text: breakMinutes.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Focus Times'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: studyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Study minutes'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: breakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Break minutes'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final int? newStudy =
                  int.tryParse(studyController.text.trim());
              final int? newBreak =
                  int.tryParse(breakController.text.trim());

              if (newStudy == null ||
                  newBreak == null ||
                  newStudy <= 0 ||
                  newBreak <= 0) return;

              timer?.cancel();

              setState(() {
                isRunning = false;
                currentMode = FocusMode.study;
                studyMinutes = newStudy;
                breakMinutes = newBreak;
                remainingSeconds = studyMinutes * 60;
                currentStudySegmentSeconds = 0;
              });

              _saveSettings();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    studyController.dispose();
    breakController.dispose();
  }

  Future<void> _commitCurrentStudySegment() async {
    if (currentStudySegmentSeconds <= 0) return;

    totalStudiedSeconds += currentStudySegmentSeconds;

    studyLogs.insert(0, {
      'date': DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now()),
      'seconds': currentStudySegmentSeconds,
    });

    if (studyLogs.length > 100) {
      studyLogs = studyLogs.sublist(0, 100);
    }

    currentStudySegmentSeconds = 0;

    await _saveStats();
  }

  void startTimer() {
    if (isRunning) return;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (currentMode == FocusMode.study) {
          currentStudySegmentSeconds++;
        }

        if (remainingSeconds > 0) {
          remainingSeconds--;
          return;
        }
      });

      if (remainingSeconds == 0) {
        _handlePhaseFinished();
      }
    });

    setState(() => isRunning = true);
  }

  Future<void> _handlePhaseFinished() async {
    if (currentMode == FocusMode.study) {
      await _commitCurrentStudySegment();
      setState(() {
        currentMode = FocusMode.breakTime;
        remainingSeconds = breakMinutes * 60;
      });
    } else {
      setState(() {
        currentMode = FocusMode.study;
        remainingSeconds = studyMinutes * 60;
      });
    }
  }

  Future<void> stopTimer() async {
    timer?.cancel();
    await _commitCurrentStudySegment();
    setState(() => isRunning = false);
  }

  Future<void> resetTimer() async {
    timer?.cancel();
    await _commitCurrentStudySegment();
    setState(() {
      isRunning = false;
      currentMode = FocusMode.study;
      remainingSeconds = studyMinutes * 60;
    });
  }

  Widget _buildTimeBox(String text) {
    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String text, VoidCallback onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Text(text,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int hrs = remainingSeconds ~/ 3600;
    int mins = (remainingSeconds % 3600) ~/ 60;
    int secs = remainingSeconds % 60;

    String f(int v) => v.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const BottomAppBar(
        child: TaskBar(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'THE\nFOCUS',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  currentMode == FocusMode.study ? 'Study Time' : 'Break Time',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Study ${studyMinutes}m  |  Break ${breakMinutes}m',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: _buildButton('Set Times', _setCustomTimes),
              ),
              const SizedBox(height: 14),
              Center(
                child: isRunning
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton('Stop', () {
                            stopTimer();
                          }),
                          const SizedBox(width: 12),
                          _buildButton('Reset', () {
                            resetTimer();
                          }),
                        ],
                      )
                    : _buildButton('Let\'s Focus!', () {
                        startTimer();
                      }),
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  height: 220,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'lib/assets/animation.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
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
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Study Log',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (studyLogs.isEmpty)
              const Text("No study time logged yet.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: studyLogs.length > 8 ? 8 : studyLogs.length,
                itemBuilder: (context, index) {
                  final log = studyLogs[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(log['date']),
                          Text(
                            formatDuration(log['seconds']),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}