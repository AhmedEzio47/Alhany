import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/services/audio_recorder.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/services/permissions_service.dart';
import 'package:dubsmash/widgets/custom_modal.dart';
import 'package:dubsmash/widgets/loader.dart';
import 'package:dubsmash/widgets/music_player.dart';
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

  MusicPlayer _melodyPlayer;
  AudioRecorder recorder;

  String recordingFilePath;
  String recordingFilePathMp3 = '/sdcard/download/';
  String melodyPath = '/sdcard/download/';
  String mergedFilePath = '/sdcard/download/';
  bool isMicrophoneGranted = false;
  var _currentRecordingStatus = RecordingStatus.Unset;
  FlutterFFmpeg flutterFFmpeg;

  String _isDuplicate;

  _changeText() {
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
    Navigator.of(context).push(CustomModal(
        child: FlipLoader(
            loaderBackground: MyColors.primaryColor,
            iconColor: Colors.white,
            icon: Icons.music_note,
            animationType: "full_flip")));

    String filePath = await AppUtil.downloadFile(widget.melody.audioUrl);
    setState(() {
      melodyPath = filePath;
      mergedFilePath +=
          '${path.basenameWithoutExtension(filePath)}_new${path.extension(filePath)}';
    });
    Navigator.of(context).pop();
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
    await _melodyPlayer.stop();
    setState(() {
      _currentRecordingStatus = RecordingStatus.Stopped;
    });

    Recording result = await recorder.stopRecording();
    recordingFilePath = result.path;
    //TODO use in case of need of conversion
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
    String recordId;

    _isDuplicate == null
        ? recordId = randomAlphaNumeric(20)
        : recordId = _isDuplicate;

    String url = await AppUtil.uploadFile(File(mergedFilePath), context,
        'records/${widget.melody.id}/$recordId${path.extension(mergedFilePath)}');

    await DatabaseService.saveRecord(widget.melody.id, recordId, url);

    AppUtil.showToast('Submitted!');
  }

  Widget _headphonesDialog() {
    return Container(
        height: 200,
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Colors.grey,
          image: DecorationImage(
            colorFilter: new ColorFilter.mode(
                Colors.black.withOpacity(0.4), BlendMode.dstOut),
            image: AssetImage(Strings.headphones_alert_bg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'For optimal result, please put some headphones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: OutlineButton(
                  borderSide: const BorderSide(
                    color: Colors.black87,
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(20.0)),
                  child: Text('OK',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    print('hey I\'m here');
                    _changeText();
                  },
                ),
              ),
            )
          ],
        ));
  }

  initRecorder() async {
    recorder = AudioRecorder();
    recordingFilePath = await recorder.init();
  }

  @override
  void initState() {
    _melodyPlayer = MusicPlayer(
      url: widget.melody.audioUrl,
      backColor: Colors.transparent,
    );
    flutterFFmpeg = FlutterFFmpeg();
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
            image: AssetImage(Strings.default_melody_page_bg),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                  ),
                  Container(
                      width: 150,
                      height: 150,
                      child: Image.asset(Strings.default_melody_image)),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    widget.melody.name,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
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
                      if (_currentRecordingStatus ==
                          RecordingStatus.Recording) {
                        await _saveRecord();
                      } else {
                        if ((await PermissionsService()
                                .hasStoragePermission()) &&
                            (await PermissionsService()
                                .hasMicrophonePermission())) {
                          String isDuplicate =
                              await DatabaseService.checkForDuplicateRecords(
                                  widget.melody.id);
                          setState(() {
                            _isDuplicate = isDuplicate;
                          });
                          if (isDuplicate != null) {
                            AppUtil.showAlertDialog(
                                context: context,
                                heading: 'Duplicate Record',
                                message:
                                    'You have recorded on this melody before, do you want to overwrite it?',
                                firstBtnText: 'Yes',
                                firstFunc: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(CustomModal(
                                    child: _headphonesDialog(),
                                  ));
                                },
                                secondBtnText: 'No',
                                secondFunc: () {
                                  Navigator.of(context).pop();
                                });
                          } else {
                            Navigator.of(context).push(CustomModal(
                              child: _headphonesDialog(),
                            ));
                          }
                        }
                        if (!await PermissionsService()
                            .hasStoragePermission()) {
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
                          color: Colors.grey.shade300, shape: BoxShape.circle),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Icon(
                          _currentRecordingStatus == RecordingStatus.Recording
                              ? Icons.stop
                              : Icons.mic,
                          color: MyColors.primaryColor,
                          size: 70,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  )
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
      ),
    );
  }
}
