import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/shared/taskbar.dart';


class Notes extends StatefulWidget {
  const Notes ({super.key});

  @override
  State<Notes> createState() => _HomeState();
}

class _HomeState extends State<Notes> {

  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  void createNote() {
      showDialog(
              context: context, 
              builder: (context) {
                return Dialog(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.black,
                        width: 3,
                      )
                    ),
                    width: 750,
                    height: 700,


                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20,),
                        Text(
                          "Create A New Note",
                           style: GoogleFonts.montserrat(
                           fontSize: 23, 
                           fontWeight: FontWeight.bold, 
                          )
                        ),

                        SizedBox(height: 20,),

                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: titleController,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              focusColor: Colors.black,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                )
                              ),
                              label: Text("Title"), 
                              floatingLabelStyle: TextStyle(
                                color: Colors.black,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        SizedBox(height: 30,),

                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: contentController,
                            keyboardType: TextInputType.multiline,
                            maxLines: 15,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              label: Text("Write your note here"),
                              floatingLabelStyle: TextStyle(color: Colors.black),
                              focusColor: Colors.black,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                )
                              ),
                              border: OutlineInputBorder(),
                          
                          ),
                        ),
                        ),

                        SizedBox(height: 50,),

                        FilledButton(
                        onPressed: (){

                        }, 

                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white, 
                          elevation: 8,
                          side: BorderSide(
                            color: Colors.black,
                            width: 2
                          ) 
                          
                        ),

                        child: Text("Submit", style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.black,
                        ),), 
                        
                        )
                      ],
                    ),

                  ),
                );
              }
      );
  }

  void formHandler() {


  }


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
          onPressed: createNote,

        
          icon: Icon(Icons.add), iconSize: 35,),
          SizedBox(width: 20,)
          
        ]

     ),

      bottomNavigationBar: BottomAppBar(

        child: TaskBar(),

      ),


      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20,),

          Expanded(

            child: GridView.count(
              primary: false,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 2,
              children: [
               NoteContainer(NoteData(
                 title: "CIS 2202",
                 content: "Hello", 
                 date: "02/27/22",
               )),
               NoteContainer(NoteData(
                 title: "CIS 2202",
                 content: "Hello", 
                 date: "02/27/22",

               )),
                NoteContainer(NoteData(
                 title: "CIS 2202",
                 content: "Hello", 
                 date: "02/27/22",
               )),
               NoteContainer(NoteData(
                 title: "CIS 2202",
                 content: "Hello", 
                 date: "02/27/22",
               )),
            
                       
            
            
              ],
            ),
          ),

        ],
      ),


    );
  }
}


class NoteContainer extends StatelessWidget {

  const NoteContainer(
    this.noteData, 
    {super.key}
  );

  final NoteData noteData; 

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(

          onTap: () {
            
          },

          child: Container(
            width: 175,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.black, 
                width: 2, 
              )
          
          
            ),
          ),
        ), 
        Text(
          noteData.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17 
          ),

        ), 
        Text(
          noteData.date,

        ),
      ],
    );
  }
}
