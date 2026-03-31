import 'package:flutter/material.dart';

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

          TaskIcon("lib/assets/home.png"),
          TaskIcon("lib/assets/planner.png"),
          TaskIcon("lib/assets/focus.png"),
          TaskIcon("lib/assets/notes.png"),

        ]
       
      ),
    );
  }
}

class TaskIcon extends StatelessWidget {
  const TaskIcon(this.path ,{super.key});
  final String path; 

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
        print("Hello world");
      },
    );
  }
}