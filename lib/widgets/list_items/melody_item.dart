import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:flutter/material.dart';

class MelodyItem extends StatefulWidget {
  final Melody melody;

  MelodyItem({Key key, this.melody}) : super(key: key);

  @override
  _MelodyItemState createState() => _MelodyItemState();
}

class _MelodyItemState extends State<MelodyItem> {
  User author;
  @override
  void initState() {
    getAuthor();
    super.initState();
  }

  getAuthor() async {
    author = await DatabaseService.getUserWithId(widget.melody.authorId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 70,
        color: Colors.white,
        child: ListTile(
          leading: Container(
            color: Colors.grey.shade200,
            width: 50,
            height: 50,
            child: Icon(
              Icons.music_note,
              color: MyColors.primaryColor,
            ),
          ),
          title: Text(widget.melody.name),
          subtitle: Text(author?.name ?? ''),
        ),
      ),
    );
  }
}
