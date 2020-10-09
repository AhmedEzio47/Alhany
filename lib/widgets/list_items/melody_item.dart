import 'package:dubsmash/constants/strings.dart';
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
  User _author;
  @override
  void initState() {
    getAuthor();
    super.initState();
  }

  getAuthor() async {
    User author = await DatabaseService.getUserWithId(widget.melody.authorId);
    setState(() {
      _author = author;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 70,
        color: Colors.white.withOpacity(.4),
        child: ListTile(
          leading: Container(
              width: 50,
              height: 50,
              child: Image.asset(Strings.default_melody_image)),
          title: Text(widget.melody.name),
          subtitle: Text(_author?.name ?? ''),
        ),
      ),
    );
  }
}
