import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studybuddy/models/note_data.dart';
import 'package:studybuddy/models/note_database.dart';
import 'package:studybuddy/shared/taskbar.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _HomeState();
}

class _HomeState extends State<Notes> {
  NoteDatabase database = NoteDatabase();
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
              border: Border.all(color: Colors.black, width: 3),
            ),
            width: 750,
            height: 700,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  "Create A New Note",
                  style: GoogleFonts.montserrat(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20),

                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: titleController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      focusColor: Colors.black,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      label: Text("Title"),
                      floatingLabelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                SizedBox(height: 30),

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
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                SizedBox(height: 50),

                FilledButton(
                  onPressed: formHandler,

                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 8,
                    side: BorderSide(color: Colors.black, width: 2),
                  ),

                  child: Text(
                    "Submit",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  void formHandler() {
    NoteData data = NoteData(
      title: titleController.text,
      content: contentController.text,
      date: DateTime.now().year.toString() + "/" + DateTime.now().month.toString() + "/" + DateTime.now().day.toString(),
    );

      database.addNote(data);

      titleController.clear();

      contentController.clear();



      setState(() {
        
      });


      Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         elevation: 0,
        backgroundColor: Colors.transparent,

      ),

      bottomNavigationBar: BottomAppBar(child: TaskBar()),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20,),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "THE\nNOTES",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    
                  ),
                ),
              ),

SizedBox(width: 150,),

              Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.blue,
  ),
  child: IconButton(
    onPressed: () {
      createNote();
    },
    icon: Icon(Icons.add, color: Colors.white),
  ),
),
SizedBox(width: 20,)

            ],
          ),

          const SizedBox(height: 30),


          SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
            
              itemBuilder: (context, index) {
                NoteData data = database.getAllNotes()[index];
                return NoteContainer(data, index, () {
                    database.removeNote(index);
                    setState(() {
                      
                    });
                    Navigator.pop(context);
                });
              },
              itemCount: database.getAllNotes().length,
            ),
          )

        ],
      ),
    );
  }
}

class NoteContainer extends StatelessWidget {
  const NoteContainer(this.noteData, this.noteIndex, this.onDelete ,{super.key});

  final NoteData noteData;
  final int noteIndex;
  final VoidCallback onDelete;



  @override
  Widget build(BuildContext context) {

    void viewNote() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 3),
            ),
            width: 750,
            height: 700,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  noteData.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(10),
                    children: [
                      Text(
                       noteData.content,
                       style: GoogleFonts.montserrat(
                       fontSize: 15, 
                      ),
                      textAlign: TextAlign.center,
                    ),
                  
                    ],
                  ),
                ),

                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                  FilledButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.arrow_back),

                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 8,
                    side: BorderSide(color: Colors.black, width: 2),
                  )
                  ),

                  FilledButton(
                  onPressed:onDelete
                  ,
                  child: Icon(Icons.delete),

                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 8,
                    side: BorderSide(color: Colors.black, width: 2),
                  )
                  ),


                  ],


                )


              ],
              
            ),
          ),
        );
      },
    );
  }


    return Column(
      children: [
        GestureDetector(
          onTap: () {
            viewNote();
          },

          child: Container(
            width: 175,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
        ),
        Text(
          noteData.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        Text(noteData.date),
      ],
    );
  }
}
