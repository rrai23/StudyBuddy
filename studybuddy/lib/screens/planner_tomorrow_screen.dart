import 'package:flutter/material.dart';
import '../shared/planner_tabs.dart';

class PlannerTomorrowScreen extends StatelessWidget {
  const PlannerTomorrowScreen({super.key});

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '3:27',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.signal_cellular_alt, size: 18),
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
                const SizedBox(height: 20),
                const PlannerTabs(selectedTab: 'tomorrow'),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Friday',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '15',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            height: 0.9,
                          ),
                        ),
                        Text(
                          'MARCH',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 1,
                      height: 150,
                      color: Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: Colors.black38,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        padding: EdgeInsets.zero,
                        children: const [
                          PlannerCard(
                            title: 'You Have A\nMeeting',
                            time: '03:10 PM',
                            location: 'Radisson Blu',
                          ),
                          SizedBox(height: 14),
                          PlannerCard(
                            title: 'You Have A\nDinner w/ Guests',
                            time: '06:30 PM',
                            location: 'Asmara',
                          ),
                          SizedBox(height: 14),
                          PlannerCard(
                            title: 'You Have A\nMeeting',
                            time: '08:45 PM',
                            location: 'Office',
                          ),
                          SizedBox(height: 70),
                        ],
                      ),
                      Positioned(
                        right: 2,
                        top: 8,
                        bottom: 75,
                        child: Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 48,
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
      ),
    );
  }
}

class PlannerCard extends StatelessWidget {
  final String title;
  final String time;
  final String location;

  const PlannerCard({
    super.key,
    required this.title,
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black45, width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}