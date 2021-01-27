import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class UploadSingleLevelMelody extends StatefulWidget {
  @override
  _UploadSingleLevelMelodyState createState() =>
      _UploadSingleLevelMelodyState();
}

class _UploadSingleLevelMelodyState extends State<UploadSingleLevelMelody> {
  String _melodyName;
  File _image;
  String _price;

  List<String> _singersNames = [];
  List<Singer> _singers = [];

  String _singerName;
  Singer _singer;

  getSingers() async {
    _singersNames = [];
    QuerySnapshot singersSnapshot = await singersRef.get();
    for (DocumentSnapshot doc in singersSnapshot.docs) {
      setState(() {
        _singersNames.add(doc.data()['name']);
      });
    }
  }

  @override
  void initState() {
    getSingers();
    super.initState();
  }

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
              Text(
                'Note: Price and singer applies for both single and multiple melodies',
                style: TextStyle(color: MyColors.accentColor),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
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
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: DropdownButton(
                      hint: Text('Singer'),
                      value: _singerName,
                      onChanged: (text) async {
                        Singer singer =
                            await DatabaseService.getSingerWithName(text);
                        setState(() {
                          _singer = singer;
                          _singerName = text;
                        });
                      },
                      items: (_singersNames)
                          .map<DropdownMenuItem<dynamic>>((dynamic value) {
                        return DropdownMenuItem<dynamic>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      textAlign: TextAlign.center,
                      onChanged: (text) {
                        setState(() {
                          _price = text;
                        });
                      },
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Price',
                      ),
                    ),
                  ),
                ],
              ),
              RaisedButton(
                  color: MyColors.primaryColor,
                  child: Text(
                    language(
                        en: Strings.en_choose_melody,
                        ar: Strings.ar_choose_melody),
                    style: TextStyle(color: MyColors.textLightColor),
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
                        decoration:
                            BoxDecoration(border: Border.all(width: 0.25)),
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
                        decoration:
                            BoxDecoration(border: Border.all(width: 0.25)),
                      ),
                    ),
                  ],
                ),
              ),
              RaisedButton(
                  color: MyColors.primaryColor,
                  child: Text(
                    language(
                        en: Strings.en_choose_melodies,
                        ar: Strings.ar_choose_melodies),
                    style: TextStyle(color: MyColors.textLightColor),
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
    String fileNameWithoutExtension =
        path.basenameWithoutExtension(melodyFile.path);

    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info =
        await _flutterFFprobe.getMediaInformation(melodyFile.path);
    int duration =
        double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    AppUtil.showLoader(context);
    String id = randomAlphaNumeric(20);
    String melodyUrl =
        await AppUtil().uploadFile(melodyFile, context, '/melodies/$id$ext');
    String imageUrl;
    if (_image != null) {
      String ext = path.extension(_image.path);
      imageUrl = await AppUtil()
          .uploadFile(_image, context, '/melodies_images/$id$ext');
    }

    if (melodyUrl == '') {
      print('no file chosen error');
      AppUtil.showToast('No files chosen');
      Navigator.of(context).pop();
      return;
    }

    await melodiesRef.doc(id).set({
      'name': _melodyName ?? fileNameWithoutExtension,
      'audio_url': melodyUrl,
      'image_url': imageUrl,
      'author_id': _singerName == null ? Constants.currentUserID : null,
      'singer': _singerName,
      'is_song': false,
      'price': _price,
      'search': _melodyName != null
          ? searchList(_melodyName)
          : searchList(fileNameWithoutExtension),
      'duration': duration,
      'timestamp': FieldValue.serverTimestamp()
    });
    if (_singer != null) {
      await singersRef
          .doc(_singer.id)
          .update({'melodies': FieldValue.increment(1)});
    }

    Navigator.of(context).pop();
    AppUtil.showToast(language(
        en: Strings.en_melody_uploaded, ar: Strings.ar_melody_uploaded));
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
      String fileNameWithoutExtension =
          path.basenameWithoutExtension(melodyFile.path);
      String melodyUrl = await AppUtil()
          .uploadFile(melodyFile, context, '/melodies/$id$melodyExt');
      final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
      MediaInformation info =
          await _flutterFFprobe.getMediaInformation(melodyFile.path);
      int duration =
          double.parse(info.getMediaProperties()['duration'].toString())
              .toInt();

      await melodiesRef.doc(id).set({
        'name': fileNameWithoutExtension,
        'audio_url': melodyUrl,
        'author_id': _singerName == null ? Constants.currentUserID : null,
        'singer': _singerName,
        'is_song': false,
        'price': _price,
        'search': searchList(fileNameWithoutExtension),
        'duration': duration,
        'timestamp': FieldValue.serverTimestamp()
      });
      await singersRef
          .doc(_singer.id)
          .update({'melodies': FieldValue.increment(melodiesFiles.length)});
    }
    AppUtil.showToast(language(en: 'Melodies uploaded!', ar: 'تم رفع الألحان'));
    Navigator.of(context).pop();
  }
}
