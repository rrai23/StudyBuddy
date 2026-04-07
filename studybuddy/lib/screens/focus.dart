import 'package:flutter/material.dart';
import 'dart:async';

import 'package:studybuddy/shared/taskbar.dart';


class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Main();
  }
}
class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  final GlobalKey<__TimStateState> timerKey = GlobalKey<__TimStateState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
       bottomNavigationBar: BottomAppBar(

        child: TaskBar(),

      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "THE\nFOCUS",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Center(child: _TimState(key: timerKey)),

          const SizedBox(height: 30),

          const Center(child: _visState()),

          const SizedBox(height: 30),

          Center(
            child: _buttonState(
              onStart: () {
                timerKey.currentState?.startTimer();
              },
              onStop: () {
                timerKey.currentState?.stopTimer();
              },
              onReset: () {
                timerKey.currentState?.resetTimer();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimState extends StatefulWidget {
  const _TimState({super.key});

  @override
  State<_TimState> createState() => __TimStateState();
}

class __TimStateState extends State<_TimState> {
  int hrs = 0;
  int mins = 0;
  int secs = 0;
  Timer? timer;
  bool isRunning = false;

  String format(int value) => value.toString().padLeft(2, '0');

  void startTimer() {
    if (isRunning) return;

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secs++;
        if (secs == 60) {
          secs = 0;
          mins++;
        }
        if (mins == 60) {
          mins = 0;
          hrs++;
        }
      });
    });

    setState(() {
      isRunning = true;
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      hrs = 0;
      mins = 0;
      secs = 0;
      isRunning = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget buildBox(String text) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildBox(format(hrs)),
            const SizedBox(width: 8),
            const Text(":", style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            buildBox(format(mins)),
            const SizedBox(width: 8),
            const Text(":", style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            buildBox(format(secs)),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 70, child: Center(child: Text("Hours"))),
            SizedBox(width: 30),
            SizedBox(width: 70, child: Center(child: Text("Minutes"))),
            SizedBox(width: 30),
            SizedBox(width: 70, child: Center(child: Text("Seconds"))),
          ],
        ),
      ],
    );
  }
}

class _visState extends StatefulWidget {
  const _visState({super.key});

  @override
  State<_visState> createState() => __visStateState();
}

class __visStateState extends State<_visState> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
  'lib/assets/animation.gif',
  fit: BoxFit.contain,
),
      ),
    );
  }
}

class _buttonState extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const _buttonState({
    super.key,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  @override
  State<_buttonState> createState() => __buttonStateState();
}

class __buttonStateState extends State<_buttonState> {
  bool isRunning = false;

  Widget buildBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isRunning
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildBtn("Stop", () {
                widget.onStop();
                setState(() => isRunning = false);
              }),
              const SizedBox(width: 12),
              buildBtn("Reset", widget.onReset),
            ],
          )
        : buildBtn("Let’s Focus!", () {
            widget.onStart();
            setState(() => isRunning = true);
          });
  }
}