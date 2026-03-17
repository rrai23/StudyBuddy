import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studybuddy/shared/taskbar.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(
          "GOOD MORNING", 
          style: GoogleFonts.montserrat(
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
          )
        ),
      ),

      bottomNavigationBar: BottomAppBar(

        child: TaskBar(
        ),

      ),


      body: Placeholder(),
    );
  }
}