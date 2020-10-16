import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:flutter/material.dart';

class RecordItem extends StatefulWidget {
  final Record record;

  RecordItem({Key key, this.record}) : super(key: key);

  @override
  _RecordItemState createState() => _RecordItemState();
}

class _RecordItemState extends State<RecordItem> {
  User _singer;
  Melody _melody;

  @override
  void initState() {
    getAuthor();
    getMelody();
    super.initState();
  }

  getAuthor() async {
    User author = await DatabaseService.getUserWithId(widget.record.singerId);
    setState(() {
      _singer = author;
    });
  }

  getMelody() async {
    Melody melody = await DatabaseService.getMelodyWithId(widget.record.melodyId);
    setState(() {
      _melody = melody;
    });
  }

  void _goToProfilePage() {
    Navigator.of(context).pushNamed('/profile-page', arguments: {'user_id': widget.record.singerId});
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
          leading: InkWell(
            onTap: () {
              _goToProfilePage();
            },
            child: CachedImage(
              width: 50,
              height: 50,
              imageUrl: _singer?.profileImageUrl,
              imageShape: BoxShape.rectangle,
              defaultAssetImage: Strings.default_profile_image,
            ),
          ),
          title: Text(_singer?.name ?? ''),
          subtitle: InkWell(
            child: Text(_melody?.name ?? ''),
            onTap: () async {
              Navigator.of(context).pushNamed('/melody-page',
                  arguments: {'melody': (await DatabaseService.getMelodyWithId(widget.record.melodyId))});
            },
          ),
        ),
      ),
    );
  }
}
