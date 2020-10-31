import 'dart:async';
import 'dart:io';
import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/services/audio_recorder.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:Alhany/services/permissions_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class MelodyPage extends StatefulWidget {
  final Melody melody;
  static RecordingStatus recordingStatus = RecordingStatus.Unset;

  MelodyPage({Key key, this.melody}) : super(key: key);

  @override
  _MelodyPageState createState() => _MelodyPageState();
}

class _MelodyPageState extends State<MelodyPage> {
  num _countDownStart = 3;
  String _countDownText = 'Get Ready';

  bool _countDownVisible = false;

  bool isMicrophoneGranted = false;

  RecordingStatus recordingStatus = RecordingStatus.Unset;
  MusicPlayer melodyPlayer;
  AudioRecorder recorder;

  String recordingFilePath;
  String melodyPath;
  String mergedFilePath;

  FlutterFFmpeg flutterFFmpeg;

  String _isDuplicate;

  String _dropdownValue;

  String _recordingText = '';

  int _duration;

  _countDown() {
    const oneSec = const Duration(seconds: 1);
    Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_countDownStart == 0) {
          setState(() {
            _countDownText = 'GO';
            _countDownStart--;
          });
        } else if (_countDownStart < 0) {
          setState(() {
            _countDownVisible = false;
            _countDownStart = 3;
            _countDownText = 'Get Ready';
          });
          timer.cancel();
          _record();
        } else {
          setState(() {
            _countDownText = '$_countDownStart';
            _countDownStart--;
          });
        }
      },
    );
  }

  Future _downloadMelody() async {
    AppUtil.showLoader(context);

    String url;
    if (widget.melody.audioUrl != null) {
      url = widget.melody.audioUrl;
    } else if (Constants.currentMelodyLevel != null) {
      url = widget.melody.levelUrls[Constants.currentMelodyLevel];
    } else {
      url = widget.melody.levelUrls.values.elementAt(0).toString();
    }

    String filePath = await AppUtil.downloadFile(url);

    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info = await _flutterFFprobe.getMediaInformation(filePath);
    //print("File Duration: ${info.getMediaProperties()['duration']}");
    _duration = double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    setState(() {
      melodyPath = filePath;
      mergedFilePath += '${path.basenameWithoutExtension(filePath)}_new${path.extension(filePath)}';
    });
    Navigator.of(context).pop();
  }

  void _record() async {
    if (await PermissionsService().hasStoragePermission()) {
      await AppUtil.createAppDirectory();
      recordingFilePath = appTempDirectoryPath;
      melodyPath = appTempDirectoryPath;
      mergedFilePath = appTempDirectoryPath;

      await _downloadMelody();
    } else {
      await PermissionsService().requestStoragePermission();
    }
    if (await PermissionsService().hasMicrophonePermission()) {
      setState(() {
        isMicrophoneGranted = true;
      });
    } else {
      bool isGranted = await PermissionsService().requestMicrophonePermission(onPermissionDenied: () {
        AppUtil.showAlertDialog(
            context: context,
            heading: 'info',
            message: 'You must grant this microphone access to be able to use this feature.',
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
        recordingStatus = RecordingStatus.Recording;
      });
      MelodyPage.recordingStatus = RecordingStatus.Recording;

      await initRecorder();
      String url;
      if (widget.melody.audioUrl != null) {
        url = widget.melody.audioUrl;
      } else if (Constants.currentMelodyLevel != null) {
        url = widget.melody.levelUrls[Constants.currentMelodyLevel];
      } else {
        url = widget.melody.levelUrls.values.elementAt(0).toString();
      }
      myAudioPlayer = MyAudioPlayer(url: url, onComplete: saveRecord);

      await myAudioPlayer.play();

      await recorder.startRecording(conversation: this.widget);
      _recordingTimer();
    } else {}
  }

  MyAudioPlayer myAudioPlayer;

  Widget _headphonesDialog() {
    return Container(
        height: 200,
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Colors.grey,
          image: DecorationImage(
            colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.dstOut),
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
                    style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
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
                  shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
                  child: Text('OK', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    print('hey I\'m here');
                    setState(() {
                      _countDownVisible = true;
                    });
                    _countDown();
                  },
                ),
              ),
            )
          ],
        ));
  }

  Future saveRecord() async {
    AppUtil.showLoader(context);
    await myAudioPlayer.stop();

    setState(() {
      recordingStatus = RecordingStatus.Stopped;
    });
    MelodyPage.recordingStatus = RecordingStatus.Stopped;

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

    Navigator.of(context).pop();

    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info = await _flutterFFprobe.getMediaInformation(mergedFilePath);
    int duration = double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    melodyPlayer = MusicPlayer(
      url: mergedFilePath,
      isLocal: true,
      backColor: MyColors.primaryColor,
      initialDuration: duration,
    );

    Navigator.of(context).push(CustomModal(
        onWillPop: () {
          _deleteFiles();
          Navigator.of(context).pop();
        },
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              melodyPlayer,
              SizedBox(
                height: 10,
              ),
              RaisedButton(
                onPressed: () async {
                  Navigator.of(context).pop(false);
                  await submitRecord();
                },
                color: MyColors.primaryColor,
                child: Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        )));

    print(success == 1 ? 'Failure!' : 'Success!');
  }

  submitRecord() async {
    AppUtil.showLoader(context);

    String recordId;

    _isDuplicate == null ? recordId = randomAlphaNumeric(20) : recordId = _isDuplicate;

    String url = await AppUtil.uploadFile(
        File(mergedFilePath), context, 'records/${widget.melody.id}/$recordId${path.extension(mergedFilePath)}');

    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info = await _flutterFFprobe.getMediaInformation(mergedFilePath);
    int duration = double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    await DatabaseService.saveRecord(widget.melody.id, recordId, url, duration);
    _deleteFiles();
    Navigator.of(context).pop();

    AppUtil.showToast('Submitted!');
  }

  _deleteFiles() async {
    final dir = Directory(appTempDirectoryPath);
    await dir.delete(recursive: true);
    await AppUtil.createAppDirectory();
  }

  initRecorder() async {
    recorder = AudioRecorder();
  }

  @override
  void initState() {
    DatabaseService.incrementMelodyViews(widget.melody.id);
    if (widget.melody.levelUrls != null) {
      _dropdownValue = widget.melody.levelUrls.keys.elementAt(0);
    }

    if (widget.melody.audioUrl != null) {
      initMelodyPlayer(widget.melody.audioUrl);
    } else if (Constants.currentMelodyLevel != null) {
      initMelodyPlayer(widget.melody.levelUrls[Constants.currentMelodyLevel]);
    } else {
      initMelodyPlayer(widget.melody.levelUrls.values.elementAt(0).toString());
    }

    flutterFFmpeg = FlutterFFmpeg();
    super.initState();
  }

  initMelodyPlayer(String url) async {
    setState(() {
      melodyPlayer = new MusicPlayer(
        url: url,
        backColor: Colors.transparent,
        initialDuration: widget.melody.duration,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: MyColors.primaryColor,
          image: DecorationImage(
            colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
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
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                      ),
                      CachedImage(
                        width: 150,
                        height: 150,
                        defaultAssetImage: Strings.default_melody_image,
                        imageUrl: widget.melody.imageUrl,
                        imageShape: BoxShape.rectangle,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      widget.melody.levelUrls != null
                          ? DropdownButton(
                              dropdownColor: MyColors.lightPrimaryColor,
                              iconEnabledColor: Colors.white,
                              style: TextStyle(color: Colors.white, fontSize: 16),
                              value: Constants.currentMelodyLevel ?? _dropdownValue,
                              onChanged: (choice) async {
                                Constants.currentMelodyLevel = choice;
                                Navigator.of(context)
                                    .pushReplacementNamed('/melody-page', arguments: {'melody': widget.melody});
                              },
                              items: (widget.melody.levelUrls.keys.toList())
                                  .map<DropdownMenuItem<dynamic>>((dynamic value) {
                                return DropdownMenuItem<dynamic>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            )
                          : SizedBox(
                              width: 50,
                            )
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    widget.melody.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  recordingStatus != RecordingStatus.Recording ? melodyPlayer : _recordingTimerText(),
                  SizedBox(
                    height: 30,
                  ),
                  InkWell(
                    onTap: () async {
                      if (recordingStatus == RecordingStatus.Recording) {
                        await saveRecord();
                      } else {
                        if ((await PermissionsService().hasStoragePermission()) &&
                            (await PermissionsService().hasMicrophonePermission())) {
                          String isDuplicate = await DatabaseService.checkForDuplicateRecords(widget.melody.id);
                          setState(() {
                            _isDuplicate = isDuplicate;
                          });
                          if (isDuplicate != null) {
                            AppUtil.showAlertDialog(
                                context: context,
                                heading: 'Duplicate Record',
                                message: 'You have recorded on this melody before, do you want to overwrite it?',
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
                        if (!await PermissionsService().hasStoragePermission()) {
                          await PermissionsService().requestStoragePermission();
                        }
                        if (!await PermissionsService().hasMicrophonePermission()) {
                          await PermissionsService().requestMicrophonePermission();
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            spreadRadius: 4,
                            blurRadius: 6,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Icon(
                          recordingStatus == RecordingStatus.Recording ? Icons.stop : Icons.mic,
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
            _countDownVisible
                ? Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Container(
                        color: MyColors.accentColor,
                        height: 200,
                        width: MediaQuery.of(context).size.width - 50,
                        child: Center(
                          child: Text(
                            _countDownText,
                            style: TextStyle(fontSize: 34),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
            Positioned.fill(
                child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Views: ${widget.melody.views ?? 0}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }

  _recordingTimer() {
    const oneSec = const Duration(seconds: 1);
    num counter = 0;
    Timer.periodic(
      oneSec,
      (timer) {
        if (counter == _duration || recordingStatus == RecordingStatus.Stopped) {
          timer.cancel();
          counter = 0;
        }
        counter++;
        if (mounted) {
          setState(() {
            _recordingText = '${(counter % 60).toInt()} : ${counter ~/ 60} / ${_duration % 60} : ${_duration ~/ 60}';
          });
        }
      },
    );
  }

  Widget _recordingTimerText() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Text(
        _recordingText,
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }
}
