import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class UploadMultiLevelMelody extends StatefulWidget {
  @override
  _UploadMultiLevelMelodyState createState() => _UploadMultiLevelMelodyState();
}

class _UploadMultiLevelMelodyState extends State<UploadMultiLevelMelody> {
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
                    language(en: 'Upload Melody', ar: 'رفع اللحن'),
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
    if (_melodyName.trim().isEmpty) {
      AppUtil.showToast(language(en: 'Please choose a name for the melody', ar: 'قم باختيار اسم اللحن'));
      return;
    }

    AppUtil.showLoader(context);

    Map<String, String> levelsUrls = {};
    Map<String, int> levelsDurations = {};

    String id = randomAlphaNumeric(20);

    for (String key in melodies.keys) {
      String ext = path.extension(melodies[key].path);
      String url = await AppUtil.uploadFile(melodies[key], context, '/melodies/$id\_$key$ext');

      final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
      MediaInformation info = await _flutterFFprobe.getMediaInformation(melodies[key].path);
      int duration = double.parse(info.getMediaProperties()['duration'].toString()).toInt();

      levelsUrls.putIfAbsent(key, () => url);
      levelsDurations.putIfAbsent(key, () => duration);
    }

    String imageUrl;
    if (_image != null) {
      String ext = path.extension(_image.path);
      imageUrl = await AppUtil.uploadFile(_image, context, '/melodies_images/$id$ext');
    }

    await melodiesRef.document(id).setData({
      'name': _melodyName,
      'audio_url': _melodyUrl,
      'image_url': imageUrl,
      'level_urls': levelsUrls,
      'level_durations': levelsDurations,
      'author_id': Constants.currentUserID,
      'is_song': false,
      'search': searchList(_melodyName),
      'timestamp': FieldValue.serverTimestamp()
    });

    Navigator.of(context).pop();
    AppUtil.showToast(language(en: 'Melody uploaded!', ar: 'تم رقع اللحن'));
    Navigator.of(context).pop();
  }
}
