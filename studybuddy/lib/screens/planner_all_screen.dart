import 'package:flutter/material.dart';
import '../shared/planner_tabs.dart';
import '../shared/taskbar.dart';

class PlannerAllScreen extends StatelessWidget {
  const PlannerAllScreen({super.key});

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
              const SizedBox(height: 20),
              const PlannerTabs(selectedTab: 'all'),
              const SizedBox(height: 18),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.zero,
                      children: const [
                        AllPlannerCard(
                          day: 'MON',
                          date: '20',
                          month: 'MAR',
                          items: [
                            ScheduleItem(time: '07:30', label: 'CS 2203 class'),
                            ScheduleItem(time: '12:00', label: 'Lunch w/ mom'),
                            ScheduleItem(time: '03:30', label: 'Tea making'),
                          ],
                        ),
                        SizedBox(height: 12),
                        AllPlannerCard(
                          day: 'TUE',
                          date: '21',
                          month: 'MAR',
                          items: [
                            ScheduleItem(time: '09:00', label: 'Yoga'),
                            ScheduleItem(time: '01:00', label: 'Pottery making'),
                          ],
                        ),
                        SizedBox(height: 12),
                        AllPlannerCard(
                          day: 'WED',
                          date: '22',
                          month: 'MAR',
                          items: [],
                        ),
                        SizedBox(height: 12),
                        AllPlannerCard(
                          day: 'THU',
                          date: '23',
                          month: 'MAR',
                          items: [
                            ScheduleItem(time: '08:00', label: 'Breakfast'),
                            ScheduleItem(time: '11:00', label: 'IT Free Elec'),
                            ScheduleItem(time: '06:00', label: 'Dinner w/\nFriends'),
                          ],
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                    Positioned(
                      right: 2,
                      top: 110,
                      bottom: 20,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 6,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBDBDBD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllPlannerCard extends StatelessWidget {
  final String day;
  final String date;
  final String month;
  final List<ScheduleItem> items;

  const AllPlannerCard({
    super.key,
    required this.day,
    required this.date,
    required this.month,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A26FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 0.88,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 68,
            color: Colors.white70,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: items.isEmpty
                ? const SizedBox()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    item.time,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white70,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 7,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: const Icon(Icons.add, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ScheduleItem {
  final String time;
  final String label;

  const ScheduleItem({
    required this.time,
    required this.label,
  });
}