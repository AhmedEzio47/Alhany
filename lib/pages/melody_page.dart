import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/services/audio_recorder.dart';
import 'package:dubsmash/services/permissions_service.dart';
import 'package:dubsmash/widgets/melody_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class MelodyPage extends StatefulWidget {
  final Melody melody;

  const MelodyPage({Key key, this.melody}) : super(key: key);

  @override
  _MelodyPageState createState() => _MelodyPageState();
}

class _MelodyPageState extends State<MelodyPage> {
  num _start = 3;
  String _getReadyText = 'Get Ready';
  Timer _timer;

  bool _getReady = false;

  MelodyPlayer _melodyPlayer;
  AudioRecorder recorder;

  String recordingFilePath;
  String recordingFilePathMp3 = '/sdcard/download/';
  String melodyPath = '/sdcard/download/';
  String mergedFilePath = '/sdcard/download/';
  bool isMicrophoneGranted = false;
  var _currentRecordingStatus = RecordingStatus.Unset;
  FlutterFFmpeg flutterFFmpeg;

  changeText() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            _getReadyText = 'GO';
            _start--;
          });
        } else if (_start < 0) {
          setState(() {
            _getReady = false;
            _start = 3;
            _getReadyText = 'Get Ready';
          });
          timer.cancel();
          _record();
        } else {
          setState(() {
            _getReadyText = '$_start';
            _start--;
          });
        }
      },
    );
  }

  Future _downloadMelody() async {
    String filePath = await AppUtil.downloadFile(widget.melody.audioUrl);
    setState(() {
      melodyPath = filePath;
      mergedFilePath +=
          '${path.basenameWithoutExtension(filePath)}_new${path.extension(filePath)}';
    });
  }

  void _record() async {
    if (await PermissionsService().hasStoragePermission()) {
      await _downloadMelody();
    } else {
      PermissionsService().requestStoragePermission();
      return;
    }
    if (await PermissionsService().hasMicrophonePermission()) {
      setState(() {
        isMicrophoneGranted = true;
      });
    } else {
      bool isGranted = await PermissionsService().requestMicrophonePermission(
          onPermissionDenied: () {
        AppUtil.showAlertDialog(
            context: context,
            heading: 'info',
            message:
                'You must grant this microphone access to be able to use this feature.',
            firstBtnText: 'OK',
            firstFunc: () {
              Navigator.of(context).pop();
            });
        print('Permission has been denied');
      });
      setState(() {
        isMicrophoneGranted = isGranted;
      });
      return;
    }

    if (isMicrophoneGranted) {
      setState(() {
        _currentRecordingStatus = RecordingStatus.Recording;
      });
      await initRecorder();
      await _melodyPlayer.play();
      await recorder.startRecording(conversation: this.widget);
    } else {}
  }

  _saveRecord() async {
    _melodyPlayer.stop();
    setState(() {
      _currentRecordingStatus = RecordingStatus.Stopped;
    });

    Recording result = await recorder.stopRecording();
    recordingFilePath = result.path;
//                          recordingFilePathMp3 +=
//                              path.basenameWithoutExtension(recordingFilePath) +
//                                  '.mp3';
//
//                          int convertSuccess = await flutterFFmpeg.execute(
//                              '-i $recordingFilePath -vn -ar 44100 -ac 2 -b:a 192k $recordingFilePathMp3');
//                          print(convertSuccess == 1
//                              ? 'Conversion Failure!'
//                              : 'Conversion Success!');
    int success = await flutterFFmpeg.execute(
        "-y -i $recordingFilePath -i $melodyPath -filter_complex \"[0][1]amerge=inputs=2,pan=stereo|FL<c0+c1|FR<c2+c3[a]\" -map \"[a]\" -shortest $mergedFilePath");
    AppUtil.showAlertDialog(
        context: context,
        message: 'Do you want to submit the record?',
        firstBtnText: 'Submit',
        secondBtnText: 'Preview',
        firstFunc: () async {
          await _submitRecord();
          Navigator.of(context).pop(false);
        },
        secondFunc: () {});
    print(success == 1 ? 'Failure!' : 'Success!');
  }

  _submitRecord() async {
    String recordId = randomAlphaNumeric(20);
    String url = await AppUtil.uploadFile(File(mergedFilePath), context,
        'records/${widget.melody.id}/$recordId${path.extension(mergedFilePath)}');
    await melodiesRef
        .document(widget.melody.id)
        .collection('records')
        .document(recordId)
        .setData({
      'url': url,
      'singer': Constants.currentUserID,
      'timestamp': FieldValue.serverTimestamp()
    });

    await usersRef
        .document(Constants.currentUserID)
        .collection('records')
        .document(recordId)
        .setData({
      'url': url,
      'melody': widget.melody.id,
      'timestamp': FieldValue.serverTimestamp()
    });

    AppUtil.showToast('Submitted!');
  }

  initRecorder() async {
    recorder = AudioRecorder();
    recordingFilePath = await recorder.init();
  }

  @override
  void initState() {
    _melodyPlayer = MelodyPlayer(
      url: widget.melody.audioUrl,
    );
    flutterFFmpeg = FlutterFFmpeg();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                ),
                Container(
                  color: Colors.grey.shade200,
                  width: 100,
                  height: 100,
                  child: Icon(
                    Icons.music_note,
                    color: MyColors.primaryColor,
                    size: 50,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  widget.melody.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 30,
                ),
                _melodyPlayer,
                SizedBox(
                  height: 40,
                ),
                InkWell(
                  onTap: () async {
                    if (_currentRecordingStatus == RecordingStatus.Recording) {
                      await _saveRecord();
                    } else {
                      if ((await PermissionsService().hasStoragePermission()) &&
                          (await PermissionsService()
                              .hasMicrophonePermission())) {
                        setState(() {
                          _getReady = true;
                        });
                        changeText();
                      }
                      if (!await PermissionsService().hasStoragePermission()) {
                        PermissionsService().requestStoragePermission();
                      }
                      if (!await PermissionsService()
                          .hasMicrophonePermission()) {
                        PermissionsService().requestMicrophonePermission();
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: MyColors.primaryColor, shape: BoxShape.circle),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Icon(
                        _currentRecordingStatus == RecordingStatus.Recording
                            ? Icons.stop
                            : Icons.mic,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _getReady
              ? Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Container(
                        color: MyColors.lightPrimaryColor,
                        height: 200,
                        width: MediaQuery.of(context).size.width - 50,
                        child: Center(
                          child: Text(
                            _getReadyText,
                            style: TextStyle(fontSize: 34),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container()
        ],
      ),
    );
  }
}
