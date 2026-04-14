import 'package:flutter/material.dart';
import 'package:studybuddy/screens/planner_board.dart';

class PlannerTomorrowScreen extends StatelessWidget {
  const PlannerTomorrowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlannerBoard(selectedTab: 'tomorrow');
  }
}