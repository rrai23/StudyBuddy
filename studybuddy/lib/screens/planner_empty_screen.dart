import 'package:flutter/material.dart';
import '../shared/planner_tabs.dart';
import '../shared/taskbar.dart';

class PlannerEmptyScreen extends StatelessWidget {
  const PlannerEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 32),
              const PlannerTabs(selectedTab: ''),
            ],
          ),
        ),
      ),
    );
  }
}