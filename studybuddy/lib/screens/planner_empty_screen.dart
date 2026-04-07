import 'package:flutter/material.dart';
import '../shared/planner_tabs.dart';

class PlannerEmptyScreen extends StatelessWidget {
  const PlannerEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 330,
            height: 680,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3:27',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_alt, size: 18),
                        SizedBox(width: 4),
                        Icon(Icons.wifi, size: 18),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full, size: 18),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
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
      ),
    );
  }
}