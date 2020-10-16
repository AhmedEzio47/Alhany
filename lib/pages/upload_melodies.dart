import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class UploadMelodies extends StatefulWidget {
  @override
  _UploadMelodiesState createState() => _UploadMelodiesState();
}

class _UploadMelodiesState extends State<UploadMelodies> {
  Map<String, File> melodies = {};

  String _melodyName;
  String _melodyUrl;
  File _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
              ),
              Container(
                  height: 200,
                  width: 200,
                  child: _image == null
                      ? InkWell(
                          onTap: () async {
                            File image = await AppUtil.pickImageFromGallery();
                            setState(() {
                              _image = image;
                            });
                          },
                          child: Image.asset(Strings.default_melody_image))
                      : Image.file(_image)),
              TextField(
                onChanged: (text) {
                  setState(() {
                    _melodyName = text;
                  });
                },
                decoration: InputDecoration(hintText: 'Melody name'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                      color: MyColors.primaryColor,
                      child: Text(
                        melodies['do'] == null ? 'Choose DO' : 'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        File melodyFile = await AppUtil.chooseAudio();
                        setState(() {
                          melodies.putIfAbsent('do', () => melodyFile);
                        });
                      }),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                      color: MyColors.primaryColor,
                      child: Text(
                        melodies['re'] == null ? 'Choose RE' : 'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        File melodyFile = await AppUtil.chooseAudio();
                        setState(() {
                          melodies.putIfAbsent('re', () => melodyFile);
                        });
                      })
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                      color: MyColors.primaryColor,
                      child: Text(
                        melodies['mi'] == null ? 'Choose MI' : 'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        File melodyFile = await AppUtil.chooseAudio();
                        setState(() {
                          melodies.putIfAbsent('mi', () => melodyFile);
                        });
                      })
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                      color: MyColors.primaryColor,
                      child: Text(
                        melodies['fa'] == null ? 'Choose FA' : 'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        File melodyFile = await AppUtil.chooseAudio();
                        setState(() {
                          melodies.putIfAbsent('fa', () => melodyFile);
                        });
                      })
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                      color: MyColors.primaryColor,
                      child: Text(
                        melodies['sol'] == null ? 'Choose SOL' : 'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        File melodyFile = await AppUtil.chooseAudio();
                        setState(() {
                          melodies.putIfAbsent('sol', () => melodyFile);
                        });
                      })
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                      color: MyColors.primaryColor,
                      child: Text(
                        melodies['la'] == null ? 'Choose LA' : 'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        File melodyFile = await AppUtil.chooseAudio();
                        setState(() {
                          melodies.putIfAbsent('la', () => melodyFile);
                        });
                      })
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                      color: MyColors.primaryColor,
                      child: Text(
                        melodies['si'] == null ? 'Choose SI' : 'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        File melodyFile = await AppUtil.chooseAudio();
                        setState(() {
                          melodies.putIfAbsent('si', () => melodyFile);
                        });
                      })
                ],
              ),
              SizedBox(
                height: 20,
              ),
              RaisedButton(
                  color: MyColors.primaryColor,
                  child: Text(
                    'Upload Melody',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  onPressed: () async {
                    await uploadMelody();
                  })
            ],
          ),
        ),
      ),
    );
  }

  uploadMelody() async {
    if (_melodyName.isEmpty) {
      AppUtil.showToast('Please choose a name for the melody');
      return;
    }
    AppUtil.showLoader(context);

    Map<String, String> levelsUrls = {};

    for (String key in melodies.keys) {
      String ext = path.extension(melodies[key].path);
      String url = await AppUtil.uploadFile(melodies[key], context, '/melodies/$_melodyName\_$key$ext');
      levelsUrls.putIfAbsent(key, () => url);
    }

    String imageUrl;
    if (_image != null) {
      String ext = path.extension(_image.path);
      imageUrl = await AppUtil.uploadFile(_image, context, '/melodies_images/$_melodyName$ext)');
    }

    await melodiesRef.add({
      'name': _melodyName,
      'description': 'Something about the melody',
      'audio_url': _melodyUrl,
      'image_url': imageUrl,
      'level_urls': levelsUrls,
      'author_id': Constants.currentUserID,
      'is_song': false,
      'timestamp': FieldValue.serverTimestamp()
    });
    Navigator.of(context).pop();
    AppUtil.showToast('Melody uploaded!');
    Navigator.of(context).pop();
  }
}
