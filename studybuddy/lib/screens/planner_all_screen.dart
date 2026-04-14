import 'package:flutter/material.dart';
import 'package:studybuddy/screens/planner_board.dart';

class PlannerAllScreen extends StatelessWidget {
  const PlannerAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlannerBoard(selectedTab: 'all');
  }
}