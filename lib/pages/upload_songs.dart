import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/widgets/custom_modal.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class UploadSongs extends StatefulWidget {
  @override
  _UploadSongsState createState() => _UploadSongsState();
}

class _UploadSongsState extends State<UploadSongs> {
  String _songName;
  File _image;

  String _price;

  List<String> _singers = [];

  String _selectedSinger;

  getSingers() async {
    _singers = [];
    QuerySnapshot singersSnapshot = await singersRef.getDocuments();
    for (DocumentSnapshot doc in singersSnapshot.documents) {
      setState(() {
        _singers.add(doc.data['name']);
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
                height: 50,
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
              Text(
                'Note: Price and singer applies for both single and multiple songs',
                style: TextStyle(color: MyColors.accentColor),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 7,
                      child: DropdownButton(
                        hint: Text('Singer'),
                        value: _selectedSinger,
                        onChanged: (text) {
                          setState(() {
                            _selectedSinger = text;
                          });
                        },
                        items: (_singers).map<DropdownMenuItem<dynamic>>((dynamic value) {
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
                    Expanded(
                      flex: 3,
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
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
                    style: TextStyle(color: Colors.white),
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
                    'Upload Multiple Songs',
                    style: TextStyle(color: Colors.white),
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

  addSinger() {
    Navigator.of(context).pushNamed('/add-singer');

    getSingers();
  }

  uploadSong() async {
//    if (_songName.trim().isEmpty) {
//      AppUtil.showToast('Please choose a name for the song');
//      return;
//    }
    File songFile = await AppUtil.chooseAudio();
    String ext = path.extension(songFile.path);
    String fileNameWithoutExtension = path.basenameWithoutExtension(songFile.path);
    AppUtil.showLoader(context);
    String id = randomAlphaNumeric(20);
    String songUrl = await AppUtil.uploadFile(songFile, context, '/songs/$id$ext');
    String imageUrl;
    if (_image != null) {
      String ext = path.extension(_image.path);
      imageUrl = await AppUtil.uploadFile(_image, context, '/melodies_images/$id$ext');
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
      'price': _price,
      'singer': _selectedSinger,
      'search': searchList(_songName),
      'timestamp': FieldValue.serverTimestamp()
    });

    Navigator.of(context).pop();
    AppUtil.showToast('Song uploaded!');
  }

  uploadSongs() async {
    List<File> songFiles = await AppUtil.chooseAudio(multiple: true);
    if (songFiles.length == 0) {
      print('no file chosen error');
      return;
    }
    AppUtil.showLoader(context);

    for (File songFile in songFiles) {
      String id = randomAlphaNumeric(20);
      String songExt = path.extension(songFile.path);
      String fileNameWithoutExtension = path.basenameWithoutExtension(songFile.path);
      String songUrl = await AppUtil.uploadFile(songFile, context, '/songs/$id$songExt');

      await melodiesRef.document(id).setData({
        'name': fileNameWithoutExtension,
        'audio_url': songUrl,
        'is_song': true,
        'price': _price,
        'singer': _selectedSinger,
        'search': searchList(fileNameWithoutExtension),
        'timestamp': FieldValue.serverTimestamp()
      });
    }
    AppUtil.showToast('Songs uploaded!');
    Navigator.of(context).pop();
  }
}
