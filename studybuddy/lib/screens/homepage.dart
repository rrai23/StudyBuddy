import 'package:flutter/material.dart';
import 'package:studybuddy/shared/taskbar.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      /// BOTTOM TASKBAR
      bottomNavigationBar: BottomAppBar(

        child: TaskBar(),

      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ///  TOP SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TEXT
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GOOD",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        "MORNING",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),

                  
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// DATE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thu", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    Text(
                      "14",
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("MARCH", style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Divider(thickness: 1),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  "TODAY",
                  style: TextStyle(fontSize: 18, letterSpacing: 1),
                ),
              ),

              const SizedBox(height: 15),

              /// TASK LIST (SCROLLABLE)
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}