import 'dart:io';

import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

import '../app_util.dart';

class UploadTrackPage extends StatefulWidget {
  final Melody song;

  const UploadTrackPage({Key key, this.song}) : super(key: key);
  @override
  _UploadTrackPageState createState() => _UploadTrackPageState();
}

class _UploadTrackPageState extends State<UploadTrackPage> {
  File _image;
  String _trackName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Tracks'),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: TextField(
                    textAlign: TextAlign.center,
                    onChanged: (text) {
                      setState(() {
                        _trackName = text;
                      });
                    },
                    decoration: InputDecoration(hintText: 'Track name'),
                  ),
                ),
              ),
              RaisedButton(
                  color: MyColors.primaryColor,
                  child: Text(
                    'Upload Track',
                    style: TextStyle(color: MyColors.textLightColor),
                  ),
                  onPressed: () async {
                    await uploadTrack();
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
                    'Upload Multiple Tracks',
                    style: TextStyle(color: MyColors.textLightColor),
                  ),
                  onPressed: () async {
                    await uploadTracks();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  uploadTrack() async {
    File trackFile = await AppUtil.chooseAudio();
    String ext = path.extension(trackFile.path);
    String fileNameWithoutExtension =
        path.basenameWithoutExtension(trackFile.path);
    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info =
        await _flutterFFprobe.getMediaInformation(trackFile.path);
    int duration =
        double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    AppUtil.showLoader(context);
    String id = randomAlphaNumeric(20);
    String trackUrl = await AppUtil()
        .uploadFile(trackFile, context, '/tracks/${widget.song.id}/$id$ext');
    String imageUrl;
    if (_image != null) {
      String ext = path.extension(_image.path);
      imageUrl = await AppUtil().uploadFile(
          _image, context, '/tracks_images/${widget.song.id}/$id$ext');
    }

    if (trackUrl == '') {
      print('no file chosen error');
      AppUtil.showToast('No files chosen');
      Navigator.of(context).pop();
      return;
    }

    await melodiesRef.doc(widget.song.id).collection('tracks').doc(id).set({
      'name': _trackName ?? fileNameWithoutExtension,
      'audio': trackUrl,
      'image': imageUrl,
      'duration': duration,
      'timestamp': FieldValue.serverTimestamp()
    });

    Navigator.of(context).pop();
    Navigator.of(context).pop();
    AppUtil.showToast('Track uploaded!');
  }

  uploadTracks() async {
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
      String songUrl = await AppUtil().uploadFile(
          songFile, context, '/tracks/${widget.song.id}$id$songExt');

      final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
      MediaInformation info =
          await _flutterFFprobe.getMediaInformation(songFile.path);
      int duration =
          double.parse(info.getMediaProperties()['duration'].toString())
              .toInt();

      await melodiesRef.doc(id).set({
        'name': fileNameWithoutExtension,
        'audio': songUrl,
        'duration': duration,
        'timestamp': FieldValue.serverTimestamp()
      });
    }
    AppUtil.showToast('Tracks uploaded!');
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }
}
