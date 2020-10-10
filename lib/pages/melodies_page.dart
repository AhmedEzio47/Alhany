import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/list_items/melody_item.dart';
import 'package:dubsmash/widgets/music_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class MelodiesPage extends StatefulWidget {
  @override
  _MelodiesPageState createState() => _MelodiesPageState();
}

class _MelodiesPageState extends State<MelodiesPage> {
  List<Melody> _melodies = [];
  getMelodies() async {
    List<Melody> melodies = await DatabaseService.getMelodies();
    setState(() {
      _melodies = melodies;
    });
  }

  @override
  void initState() {
    getMelodies();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: MyColors.primaryColor,
          image: DecorationImage(
            colorFilter: new ColorFilter.mode(
                Colors.black.withOpacity(0.1), BlendMode.dstATop),
            image: AssetImage(Strings.default_bg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            ListView.builder(
                itemCount: _melodies.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed('/melody-page',
                          arguments: {'melody': _melodies[index]});
                    },
                    child: MelodyItem(
                      melody: _melodies[index],
                    ),
                  );
                }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(
          Icons.add_circle,
          color: MyColors.primaryColor,
        ),
        onPressed: () async {
          await addMelody();
        },
      ),
    );
  }

  addMelody() async {
    File melodyFile = await AppUtil.chooseAudio();
    String fileName = path.basename(melodyFile.path);
    String fileNameWithoutExtension =
        path.basenameWithoutExtension(melodyFile.path);
    String melodyUrl =
        await AppUtil.uploadFile(melodyFile, context, '/melodies/$fileName');

    if (melodyUrl == '') {
      print('no file chosen error');
      return;
    }

    melodiesRef.add({
      'name': fileNameWithoutExtension,
      'description': 'Something about the melody',
      'audio_url': melodyUrl,
      'author_id': Constants.currentUserID,
      'timestamp': FieldValue.serverTimestamp()
    });

    AppUtil.showToast('Melody uploaded!');
  }
}
