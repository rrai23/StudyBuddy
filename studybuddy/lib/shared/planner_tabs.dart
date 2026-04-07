import 'package:flutter/material.dart';
import '../screens/planner_empty_screen.dart';
import '../screens/planner_today_screen.dart';
import '../screens/planner_tomorrow_screen.dart';
import '../screens/planner_all_screen.dart';

class PlannerTabs extends StatelessWidget {
  final String selectedTab;

  const PlannerTabs({
    super.key,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTabButton(
          context,
          text: 'today',
          isSelected: selectedTab == 'today',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PlannerTodayScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildTabButton(
          context,
          text: 'tomorrow',
          isSelected: selectedTab == 'tomorrow',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PlannerTomorrowScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildTabButton(
          context,
          text: 'all',
          isSelected: selectedTab == 'all',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PlannerAllScreen(),
              ),
            );
          },
          blueSelected: true,
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PlannerEmptyScreen(),
              ),
            );
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    bool blueSelected = false,
  }) {
    Color fillColor = Colors.transparent;
    Color borderColor = Colors.black;
    Color textColor = Colors.black;

    if (isSelected) {
      if (blueSelected) {
        fillColor = const Color(0xFF1A26FF);
        borderColor = const Color(0xFF1A26FF);
        textColor = Colors.white;
      } else {
        fillColor = const Color(0xFFD6D6D6);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}