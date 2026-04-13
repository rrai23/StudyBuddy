import 'package:hive/hive.dart';

part 'note_data.g.dart';

@HiveType(typeId: 0)
class NoteData {

  NoteData({
    required this.title,
    required this.content,
    required this.date,
    this.blockColorValue = 0xFF2196F3,
  });

  @HiveField(0)
  final String title;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String date;

  @HiveField(3)
  final int blockColorValue;

}
