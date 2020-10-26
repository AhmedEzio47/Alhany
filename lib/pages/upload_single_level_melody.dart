import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class UploadSingleLevelMelody extends StatefulWidget {
  @override
  _UploadSingleLevelMelodyState createState() => _UploadSingleLevelMelodyState();
}

class _UploadSingleLevelMelodyState extends State<UploadSingleLevelMelody> {
  String _melodyName;
  File _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                child: TextField(
                  textAlign: TextAlign.center,
                  onChanged: (text) {
                    setState(() {
                      _melodyName = text;
                    });
                  },
                  decoration: InputDecoration(hintText: 'Melody name'),
                ),
              ),
              RaisedButton(
                  color: MyColors.primaryColor,
                  child: Text(
                    language(en: 'Upload Melody', ar: 'رفع اللحن'),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    await uploadMelody();
                  }),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    new Expanded(
                      child: new Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(border: Border.all(width: 0.25)),
                      ),
                    ),
                    Text(
                      "OR",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    new Expanded(
                      child: new Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(border: Border.all(width: 0.25)),
                      ),
                    ),
                  ],
                ),
              ),
              RaisedButton(
                  color: MyColors.primaryColor,
                  child: Text(
                    language(en: 'Upload Multiple Melodies', ar: 'رفع الألحان'),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    await uploadMelodies();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  uploadMelody() async {
//    if (_melodyName.trim().isEmpty) {
//      AppUtil.showToast('Please choose a name for the melody');
//      return;
//    }
    File melodyFile = await AppUtil.chooseAudio();
    String ext = path.extension(melodyFile.path);
    String fileNameWithoutExtension = path.basenameWithoutExtension(melodyFile.path);
    AppUtil.showLoader(context);
    String id = randomAlphaNumeric(20);
    String melodyUrl = await AppUtil.uploadFile(melodyFile, context, '/melodies/$id$ext');
    String imageUrl;
    if (_image != null) {
      String ext = path.extension(_image.path);
      imageUrl = await AppUtil.uploadFile(_image, context, '/melodies_images/$id$ext');
    }

    if (melodyUrl == '') {
      print('no file chosen error');
      AppUtil.showToast('No files chosen');
      Navigator.of(context).pop();
      return;
    }

    await melodiesRef.document(id).setData({
      'name': _melodyName ?? fileNameWithoutExtension,
      'audio_url': melodyUrl,
      'image_url': imageUrl,
      'author_id': Constants.currentUserID,
      'is_song': false,
      'search': searchList(_melodyName),
      'timestamp': FieldValue.serverTimestamp()
    });

    Navigator.of(context).pop();
    AppUtil.showToast('Melody uploaded!');
  }

  uploadMelodies() async {
    List<File> melodiesFiles = await AppUtil.chooseAudio(multiple: true);
    if (melodiesFiles.length == 0) {
      print('no file chosen error');
      return;
    }
    AppUtil.showLoader(context);

    for (File melodyFile in melodiesFiles) {
      String id = randomAlphaNumeric(20);
      String melodyExt = path.extension(melodyFile.path);
      String fileNameWithoutExtension = path.basenameWithoutExtension(melodyFile.path);
      String melodyUrl = await AppUtil.uploadFile(melodyFile, context, '/melodies/$id$melodyExt');

      await melodiesRef.document(id).setData({
        'name': fileNameWithoutExtension,
        'audio_url': melodyUrl,
        'author_id': Constants.currentUserID,
        'is_song': false,
        'search': searchList(fileNameWithoutExtension),
        'timestamp': FieldValue.serverTimestamp()
      });
    }
    AppUtil.showToast(language(en: 'Melodies uploaded!', ar: 'تم رفع الألحان'));
    Navigator.of(context).pop();
  }
}
