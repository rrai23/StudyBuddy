import 'package:flutter/material.dart';
import 'package:studybuddy/screens/planner_board.dart';

class PlannerEmptyScreen extends StatelessWidget {
  const PlannerEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlannerBoard(selectedTab: 'today');
  }
}