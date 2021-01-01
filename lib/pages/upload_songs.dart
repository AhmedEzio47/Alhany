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

class UploadSongs extends StatefulWidget {
  final String singer;

  const UploadSongs({Key key, this.singer}) : super(key: key);
  @override
  _UploadSongsState createState() => _UploadSongsState();
}

class _UploadSongsState extends State<UploadSongs> {
  String _songName;
  File _image;

  List<String> _singersNames = [];
  //List<String> _categories = [];

  String _singerName;
  Singer _singer;
  //String _category;

  TextEditingController _categoryController = TextEditingController();

  getSingers() async {
    _singersNames = [];
    QuerySnapshot singersSnapshot = await singersRef.getDocuments();
    for (DocumentSnapshot doc in singersSnapshot.documents) {
      setState(() {
        _singersNames.add(doc.data['name']);
      });
    }
  }

//  getCategories() async {
//    _categories = [];
//    QuerySnapshot categoriesSnapshot = await categoriesRef.getDocuments();
//    for (DocumentSnapshot doc in categoriesSnapshot.documents) {
//      setState(() {
//        _categories.add(doc.data['name']);
//      });
//    }
//  }

  @override
  void initState() {
    getSingers();
    //getCategories();
    super.initState();
    setState(() {
      _singerName = widget.singer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
//        actions: [
//          Padding(
//            padding: const EdgeInsets.only(right: 8),
//            child: InkWell(
//                onTap: () async {
//                  await addCategory();
//                },
//                child: Center(child: Text('Add Category'))),
//          )
//        ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.accentColor,
        onPressed: () async {
          await addSinger();
        },
        child: Icon(Icons.person_add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
              ),
              Container(
                  height: 180,
                  width: 180,
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
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 7,
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
                    SizedBox(
                      width: 10,
                    ),
//                    Expanded(
//                      flex: 8,
//                      child: DropdownButton(
//                        hint: Text('Category'),
//                        value: _category,
//                        onChanged: (text) {
//                          setState(() {
//                            _category = text;
//                          });
//                        },
//                        items: (_categories).map<DropdownMenuItem<dynamic>>((dynamic value) {
//                          return DropdownMenuItem<dynamic>(
//                            value: value,
//                            child: Text(value),
//                          );
//                        }).toList(),
//                      ),
//                    ),
                    SizedBox(
                      width: 10,
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: TextField(
                    textAlign: TextAlign.center,
                    onChanged: (text) {
                      setState(() {
                        _songName = text;
                      });
                    },
                    decoration: InputDecoration(hintText: 'Song name'),
                  ),
                ),
              ),
              RaisedButton(
                  color: MyColors.primaryColor,
                  child: Text(
                    'Upload Song',
                    style: TextStyle(color: MyColors.textLightColor),
                  ),
                  onPressed: () async {
                    await uploadSong();
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
                    'Upload Multiple Songs',
                    style: TextStyle(color: MyColors.textLightColor),
                  ),
                  onPressed: () async {
                    await uploadSongs();
                  }),
            ],
          ),
        ),
      ),
    );
  }

//  addCategory() async {
//    Navigator.of(context).push(CustomModal(
//        child: Container(
//      height: 200,
//      color: Colors.white,
//      alignment: Alignment.center,
//      child: Column(
//        children: [
//          Padding(
//            padding: const EdgeInsets.all(8.0),
//            child: TextField(
//              controller: _categoryController,
//              textAlign: TextAlign.center,
//              decoration: InputDecoration(hintText: 'New category'),
//            ),
//          ),
//          SizedBox(
//            height: 40,
//          ),
//          RaisedButton(
//            onPressed: () async {
//              if (_categoryController.text.trim().isEmpty) {
//                AppUtil.showToast('Please enter a category');
//                return;
//              }
//              Navigator.of(context).pop();
//              AppUtil.showLoader(context);
//              await categoriesRef.add({
//                'name': _categoryController.text,
//                'search': searchList(_categoryController.text),
//              });
//              //AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
//              Navigator.of(context).pop();
//            },
//            color: MyColors.primaryColor,
//            child: Text(
//              language(en: Strings.en_add, ar: Strings.ar_add),
//              style: TextStyle(color: Colors.white),
//            ),
//          )
//        ],
//      ),
//    )));
//    getCategories();
//  }

  addSinger() {
    Navigator.of(context).pushNamed('/add-singer');
    getSingers();
  }

  uploadSong() async {
    // if (_songName.trim().isEmpty) {
    //   AppUtil.showToast('Please choose a name for the song');
    //   return;
    // }
    if (_singer == null) {
      AppUtil.showToast('Please choose a singer');
      return;
    }
    File songFile = await AppUtil.chooseAudio();
    String ext = path.extension(songFile.path);
    String fileNameWithoutExtension =
        path.basenameWithoutExtension(songFile.path);
    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info =
        await _flutterFFprobe.getMediaInformation(songFile.path);
    int duration =
        double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    AppUtil.showLoader(context);
    String id = randomAlphaNumeric(20);
    String songUrl =
        await AppUtil().uploadFile(songFile, context, '/songs/$id$ext');
    String imageUrl;
    if (_image != null) {
      String ext = path.extension(_image.path);
      imageUrl = await AppUtil()
          .uploadFile(_image, context, '/melodies_images/$id$ext');
    }

    if (songUrl == '') {
      print('no file chosen error');
      AppUtil.showToast('No files chosen');
      Navigator.of(context).pop();
      return;
    }

    await melodiesRef.document(id).setData({
      'name': _songName ?? fileNameWithoutExtension,
      'audio_url': songUrl,
      'image_url': imageUrl,
      'is_song': true,
      'singer': _singerName,
//      'category': _category,
      'search': _songName != null
          ? searchList(_songName)
          : searchList(fileNameWithoutExtension),
      'duration': duration,
      'timestamp': FieldValue.serverTimestamp()
    });
    await singersRef
        .document(_singer.id)
        .updateData({'songs': FieldValue.increment(1)});

    Navigator.of(context).pop();
    Navigator.of(context).pop();
    AppUtil.showToast('Song uploaded!');
  }

  uploadSongs() async {
    if (_singer == null) {
      AppUtil.showToast('Please choose a singer');
      return;
    }
    List<File> songFiles = await AppUtil.chooseAudio(multiple: true);
    if (songFiles.length == 0) {
      print('no file chosen error');
      return;
    }
    AppUtil.showLoader(context);

    for (File songFile in songFiles) {
      String id = randomAlphaNumeric(20);
      String songExt = path.extension(songFile.path);
      String fileNameWithoutExtension =
          path.basenameWithoutExtension(songFile.path);
      String songUrl =
          await AppUtil().uploadFile(songFile, context, '/songs/$id$songExt');

      final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
      MediaInformation info =
          await _flutterFFprobe.getMediaInformation(songFile.path);
      int duration =
          double.parse(info.getMediaProperties()['duration'].toString())
              .toInt();

      await melodiesRef.document(id).setData({
        'name': fileNameWithoutExtension,
        'audio_url': songUrl,
        'is_song': true,
        'singer': _singerName,
        'duration': duration,
        'search': searchList(fileNameWithoutExtension),
        'timestamp': FieldValue.serverTimestamp()
      });
    }
    await singersRef
        .document(_singer.id)
        .updateData({'songs': FieldValue.increment(songFiles.length)});
    AppUtil.showToast('Songs uploaded!');
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }
}
