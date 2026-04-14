import 'package:flutter/material.dart';
import 'package:studybuddy/screens/planner_board.dart';

class PlannerTodayScreen extends StatelessWidget {
  const PlannerTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlannerBoard(selectedTab: 'today');
  }
}