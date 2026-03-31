import 'package:flutter/material.dart';
import 'package:studybuddy/shared/taskbar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final dayName = DateFormat('EEE').format(now);  
    final dayNumber = DateFormat('d').format(now);  
    final month = DateFormat('MMMM').format(now);   

    String greeting;
    int hour = now.hour;

    if (hour < 12) {
      greeting = "GOOD\nMORNING";
    } else if (hour < 17) {
      greeting = "GOOD\nAFTERNOON";
    } else {
      greeting = "GOOD\nEVENING";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      bottomNavigationBar: BottomAppBar(
        child: TaskBar(),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  greeting,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),

                const SizedBox(width: 40),

                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column( 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.montserrat(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dayNumber,
                    style: GoogleFonts.montserrat(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    month.toUpperCase(),
                    style: GoogleFonts.montserrat(fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Divider(thickness: 1),

            const SizedBox(height: 10),

            Text(
              "TODAY",
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 15),

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
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}