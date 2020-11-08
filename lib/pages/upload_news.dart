import 'dart:async';
import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/services/audio_recorder.dart';
import 'package:Alhany/widgets/image_edit_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:path/path.dart' as path;

class UploadNews extends StatefulWidget {
  @override
  _UploadNewsState createState() => _UploadNewsState();
}

enum Types { RECORD_VIDEO, RECORD_AUDIO, IMAGE, CHOOSE_AUDIO, CHOOSE_VIDEO }

class _UploadNewsState extends State<UploadNews> {
  Types _type;
  bool isRecording = false;
  String _contentType;

  File _contentFile;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    AppUtil.createAppDirectory();
    recorder = AudioRecorder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload News'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(hintText: 'Title'),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: 'What\'s in your mind?'),
                minLines: 3,
                maxLines: 15,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            DropdownButton(
              dropdownColor: MyColors.lightPrimaryColor,
              iconEnabledColor: MyColors.darkPrimaryColor,
              style: TextStyle(color: MyColors.darkPrimaryColor, fontSize: 16),
              hint: Text('Content Type'),
              value: _type,
              items: [
                DropdownMenuItem(
                  child: Text('Record Audio'),
                  value: Types.RECORD_AUDIO,
                ),
                DropdownMenuItem(
                  child: Text('Record Video'),
                  value: Types.RECORD_VIDEO,
                ),
                DropdownMenuItem(
                  child: Text('Choose Audio'),
                  value: Types.CHOOSE_AUDIO,
                ),
                DropdownMenuItem(
                  child: Text('Choose Video'),
                  value: Types.CHOOSE_VIDEO,
                ),
                DropdownMenuItem(
                  child: Text('Image'),
                  value: Types.IMAGE,
                ),
              ],
              onChanged: (type) {
                setState(() {
                  _type = type;
                });
              },
            ),
            SizedBox(
              height: 10,
            ),
            _recordingTimerText(),
            SizedBox(
              height: 10,
            ),
            RaisedButton(
              onPressed: isRecording ? _stopAudioRecording : _btnPressed,
              child: Text(
                isRecording ? 'Stop' : _contentFile == null ? 'Add Content' : 'DONE',
                style: TextStyle(color: Colors.white),
              ),
              color: MyColors.primaryColor,
            ),
            SizedBox(
              height: 10,
            ),
            RaisedButton(
              onPressed: _submit,
              child: Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
              color: MyColors.primaryColor,
            )
          ],
        ),
      ),
    );
  }

  String _recordingText = '';
  Widget _recordingTimerText() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Text(
        _recordingText,
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }

  _recordingTimer() {
    const oneSec = const Duration(seconds: 1);
    num counter = 0;
    Timer.periodic(
      oneSec,
      (timer) {
        if (!isRecording) {
          counter = 0;
          timer.cancel();
        } else {
          counter++;
        }
        if (mounted) {
          setState(() {
            _recordingText = '${(counter % 60).toInt()} : ${counter ~/ 60}';
          });
        }
      },
    );
  }

  _btnPressed() async {
    switch (_type) {
      case Types.RECORD_VIDEO:
        _recordVideo();
        break;
      case Types.RECORD_AUDIO:
        _recordAudio();
        break;
      case Types.IMAGE:
        _pickImage();
        break;
      case Types.CHOOSE_AUDIO:
        _chooseAudio();
        break;
      case Types.CHOOSE_VIDEO:
        _chooseVideo();
        break;
    }
  }

  var _duration;

  getDuration(String filePath) async {
    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info = await _flutterFFprobe.getMediaInformation(filePath);
    _duration = double.parse(info.getMediaProperties()['duration'].toString()).toInt();
  }

  _recordVideo() async {
    File video = await ImagePicker.pickVideo(source: ImageSource.camera);
    setState(() {
      _contentFile = video;
      _contentType = 'video';
    });
    getDuration(_contentFile.path);
  }

  AudioRecorder recorder;
  _recordAudio() async {
    recorder.startRecording(conversation: this.widget);
    setState(() {
      isRecording = true;
    });
    _recordingTimer();
  }

  _stopAudioRecording() async {
    Recording result = await recorder.stopRecording();
    setState(() {
      isRecording = false;
    });

    setState(() {
      _contentFile = File(result.path);
    });
    getDuration(_contentFile.path);
  }

  _pickImage() async {
    ImageEditBottomSheet bottomSheet = ImageEditBottomSheet();
    await bottomSheet.openBottomSheet(context);

    File image;
    if (bottomSheet.source == ImageSource.gallery) {
      image = await AppUtil.pickImageFromGallery();
    } else if (bottomSheet.source == ImageSource.camera) {
      image = await AppUtil.takePhoto();
    } else {
      AppUtil.showToast('Nothing chosen');
      return;
    }

    setState(() {
      _contentFile = image;
      _contentType = 'image';
    });
  }

  _chooseAudio() async {
    File audio = await AppUtil.chooseAudio();
    setState(() {
      _contentFile = audio;
      _contentType = 'audio';
    });
    getDuration(_contentFile.path);
  }

  _chooseVideo() async {
    File video = await ImagePicker.pickVideo(source: ImageSource.gallery);
    setState(() {
      _contentFile = video;
      _contentType = 'video';
    });
    getDuration(_contentFile.path);
  }

  _submit() async {
    if (_textController.text.isEmpty && _contentFile == null) {
      AppUtil.showToast('Please add some content');
      return;
    }
    AppUtil.showLoader(context);
    String id = randomAlphaNumeric(20);
    String ext = path.extension(_contentFile.path);
    String url = await AppUtil.uploadFile(_contentFile, context, 'news/$id$ext');
    await newsRef.document(id).setData({
      'title': _titleController.text,
      'text': _textController.text,
      'content_url': url,
      'duration': _duration,
      'type': _contentType,
      'timestamp': FieldValue.serverTimestamp()
    });
    AppUtil.showToast('Submitted');

    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }
}
