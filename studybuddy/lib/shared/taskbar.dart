import 'package:flutter/material.dart';
import 'package:studybuddy/screens/focus.dart';
import 'package:studybuddy/screens/notes.dart';
import 'package:studybuddy/screens/homepage.dart';


class TaskBar extends StatelessWidget {
  const TaskBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.black,
          width: 2,  
        ),
        color: Colors.green[100],
      ),


      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          TaskIcon("lib/assets/home.png", () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return Homepage();
              },
            ));
          }),

          TaskIcon("lib/assets/planner.png",  () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return Notes();
              },
            ));
          }),
          TaskIcon("lib/assets/focus.png",  () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return FocusPage();
              },
            ));
          }),
          TaskIcon("lib/assets/notes.png",  () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return FocusPage();
              },
            ));
          }),

        ]
       
      ),
    );
  }
}

class TaskIcon extends StatelessWidget {
  const TaskIcon(this.path , this.onTap, {super.key});
  final String path; 
  final VoidCallback onTap;  

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child:  Image.asset(
            path, 
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            ),
      onTap: () {
        onTap();
      },
    );
  }
}