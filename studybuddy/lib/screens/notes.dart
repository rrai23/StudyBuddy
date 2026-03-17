import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studybuddy/shared/taskbar.dart';


class Notes extends StatefulWidget {
  const Notes ({super.key});

  @override
  State<Notes> createState() => _HomeState();
}

class _HomeState extends State<Notes> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            "THE", 
            style: GoogleFonts.montserrat(
            fontSize: 23, 
            fontWeight: FontWeight.bold, 
            )
          ),
          Text(
            "NOTES", 
            style: GoogleFonts.montserrat(
            fontSize: 23, 
            fontWeight: FontWeight.bold, 
            )
          ),
 
          ],
        ),

        actions: [  
          IconButton(
          onPressed: () {

          },
        
          icon: Icon(Icons.add),
          ),
          SizedBox(width: 20,)
          
        ]

     ),

      bottomNavigationBar: BottomAppBar(

        child: TaskBar(),

      ),


      body: Placeholder(),


    );
  }
}