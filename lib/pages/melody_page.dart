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
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:flutter_ffmpeg/statistics.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:path/path.dart' as path;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:random_string/random_string.dart';
import 'package:video_player/video_player.dart' as video_player;

enum Types { VIDEO, AUDIO }

class MelodyPage extends StatefulWidget {
  final Melody melody;
  final Types type;
  static RecordingStatus recordingStatus = RecordingStatus.Unset;

  MelodyPage({Key key, this.melody, this.type = Types.VIDEO}) : super(key: key);

  @override
  _MelodyPageState createState() => _MelodyPageState();
}

class _MelodyPageState extends State<MelodyPage> {
  Types _type;
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
  String imageVideoPath;

  FlutterFFmpeg flutterFFmpeg;

  String _dropdownValue;

  String _recordingText = '';

  int _duration;

  video_player.VideoPlayerController _videoController;

  bool _isVideoPlaying = false;

  File _image;

  FlutterFFmpegConfig _flutterFFmpegConfig = FlutterFFmpegConfig();

  double _recordingDuration;

  bool _progressVisible = false;

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
          if (_type == Types.AUDIO) {
            _recordAudio();
          } else {
            _recordVideo();
          }
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
    _duration =
        double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    setState(() {
      melodyPath = filePath;
      if (_type == Types.AUDIO) {
        mergedFilePath +=
            '${path.basenameWithoutExtension(filePath)}_new${path.extension(filePath)}';
      } else {
        mergedFilePath += '${path.basenameWithoutExtension(filePath)}_new.mp4';
      }
    });
    Navigator.of(context).pop();
  }

  void _recordAudio() async {
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

  CameraController cameraController;

  void _recordVideo() async {
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
        recordingStatus = RecordingStatus.Recording;
      });
      MelodyPage.recordingStatus = RecordingStatus.Recording;

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
      recordingFilePath += 'video_rec.mp4';
      try {
        File(recordingFilePath).deleteSync();
      } catch (e) {}
      cameraController.startVideoRecording(recordingFilePath);
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

    setState(() {
      recordingStatus = RecordingStatus.Stopped;
    });
    MelodyPage.recordingStatus = RecordingStatus.Stopped;

    await myAudioPlayer.stop();

    if (_type == Types.AUDIO) {
      Recording result = await recorder.stopRecording();
      recordingFilePath = result.path;
    } else {
      await cameraController.stopVideoRecording();
    }
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
    int success;
    if (_type == Types.AUDIO) {
      success = await flutterFFmpeg.execute(
          "-y -i $recordingFilePath -i $melodyPath -filter_complex \"[0][1]amerge=inputs=2,pan=stereo|FL<c0+c1|FR<c2+c3[a]\" -map \"[a]\" -shortest $mergedFilePath");
    } else {
      //STEP 1: EXTRACT AUDIO FROM VIDEO
      success = await flutterFFmpeg.execute(
          '-i $recordingFilePath ${appTempDirectoryPath}extracted_audio.mp3');
      print(success == 1 ? 'EXTRACT Failure!' : 'EXTRACT Success!');

      //STEP 2:MERGE BOTH MELODY AND EXTRACTED AUDIO
      success = await flutterFFmpeg.execute(
          "-y -i ${appTempDirectoryPath}extracted_audio.mp3 -i $melodyPath -filter_complex \"[0][1]amerge=inputs=2,pan=stereo|FL<c0+c1|FR<c2+c3[a]\" -map \"[a]\" -shortest ${appTempDirectoryPath}final_audio.mp3");
      FlutterFFprobe fFprobe = FlutterFFprobe();
      MediaInformation info = await fFprobe
          .getMediaInformation('${appTempDirectoryPath}final_audio.mp3');
      _flutterFFmpegConfig.enableStatisticsCallback(this.statisticsCallback);
      _recordingDuration = double.parse(info.getMediaProperties()['duration']);
      print(success == 1 ? 'MERGE Failure!' : 'MERGE Success!');
      Navigator.of(context).pop();
      setState(() {
        _progressVisible = true;
      });
      // MERGE VIDEO WITH FINAL AUDIO
      success = await flutterFFmpeg.execute(
          "-y -i ${appTempDirectoryPath}final_audio.mp3 -i $recordingFilePath -map 0:a -map 1:v -shortest $mergedFilePath");
      print(success == 1 ? 'FINAL Failure!' : 'FINAL Success!');
      setState(() {
        _progressVisible = false;
      });
    }

    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info =
        await _flutterFFprobe.getMediaInformation(mergedFilePath);
    int duration =
        double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    if (_type == Types.AUDIO) {
      melodyPlayer = MusicPlayer(
        url: mergedFilePath,
        isLocal: true,
        backColor: MyColors.primaryColor,
        initialDuration: duration,
      );
    } else {
      await initVideoPlayer();
    }

    Navigator.of(context).push(CustomModal(
        onWillPop: () {
          _deleteFiles();
          Navigator.of(context).pop();
        },
        child: Container(
          child: _type == Types.AUDIO
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      melodyPlayer,
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RaisedButton(
                            onPressed: imageVideoPath == null
                                ? () async {
                                    _image =
                                        await AppUtil.pickImageFromGallery();
                                    AppUtil.showLoader(context);
                                    setState(() {
                                      imageVideoPath =
                                          '${path.withoutExtension(mergedFilePath)}.mp4';
                                    });
                                    success = await flutterFFmpeg.execute(
                                        "-loop 1 -i ${_image.path} -i $mergedFilePath -c:v libx264 -tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p -shortest $imageVideoPath");
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            color: MyColors.primaryColor,
                            child: Text(
                              imageVideoPath == null ? 'Choose Image' : 'Done',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          RaisedButton(
                            onPressed: () async {
                              if (_image == null) {
                                AppUtil.showToast(language(
                                    en: 'Please choose an image',
                                    ar: 'من فضلك اختر صورة'));
                                return;
                              }
                              Navigator.of(context).pop(false);
                              await submitRecord();
                            },
                            color: MyColors.primaryColor,
                            child: Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              : Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: video_player.VideoPlayer(_videoController),
                    ),
                    Positioned.fill(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            playPauseBtn(),
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
                        alignment: Alignment.bottomCenter,
                      ),
                    )),
                  ],
                ),
        )));

    print(success == 1 ? 'Failure!' : 'Success!');
  }

  void statisticsCallback(Statistics statistics) {
    try {
      setState(() {
        _progress = statistics.time / (_recordingDuration * 1000);
      });
      print("Progress: $_progress%");
    } catch (ex) {}
  }

  Widget playPauseBtn() {
    return !_isVideoPlaying
        ? InkWell(
            onTap: () => _videoController.value.isPlaying
                ? null
                : setState(() {
                    _isVideoPlaying = true;
                    _videoController.play();
                  }),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2), // changes position of shadow
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow,
                size: 35,
                color: MyColors.primaryColor,
              ),
            ),
          )
        : InkWell(
            onTap: _videoController.value.isPlaying
                ? () => setState(() {
                      _isVideoPlaying = false;
                      _videoController.pause();
                    })
                : null,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2), // changes position of shadow
                  ),
                ],
              ),
              child: Icon(
                Icons.pause,
                color: MyColors.primaryColor,
                size: 35,
              ),
            ),
          );
  }

  double _progress = 0;
  submitRecord() async {
    //AppUtil.showLoader(context);
    setState(() {
      _progressVisible = true;
    });
    String recordId = randomAlphaNumeric(20);
    String url;
    AppUtil appUtil = AppUtil();
    appUtil.addListener(() {
      if (mounted) {
        setState(() {
          _progress = AppUtil.progress;
        });
        print('Progress: ${_progress.toStringAsFixed(1)} %');
      }
    });
    if (_type == Types.VIDEO) {
      url = await appUtil.uploadFile(File(mergedFilePath), context,
          'records/${widget.melody.id}/$recordId${path.extension(mergedFilePath)}');
    } else {
      url = await appUtil.uploadFile(File(imageVideoPath), context,
          'records/${widget.melody.id}/$recordId${path.extension(imageVideoPath)}');
    }
    setState(() {
      _progressVisible = false;
    });
    AppUtil.showLoader(context);
    final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
    MediaInformation info = await _flutterFFprobe.getMediaInformation(
        _type == Types.VIDEO ? mergedFilePath : imageVideoPath);
    int duration =
        double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    await DatabaseService.submitRecord(
        widget.melody.id, recordId, url, duration);
    _deleteFiles();
    Navigator.of(context).pop();
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

  initVideoPlayer() async {
    if (!await PermissionsService().hasStoragePermission()) {
      PermissionsService().requestStoragePermission();
    }
    _videoController =
        video_player.VideoPlayerController.file(File(mergedFilePath));
    await _videoController.initialize();
  }

  @override
  void initState() {
    setState(() {
      _type = widget.type;
    });
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
    if (_type == Types.VIDEO) {
      _initCamera();
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
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: _progressVisible
            ? progressPage()
            : recordingStatus == RecordingStatus.Recording &&
                    _type == Types.VIDEO
                ? videoRecordingPage()
                : mainPage(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (recordingStatus == RecordingStatus.Recording) {
              await saveRecord();
            } else {
              if ((await PermissionsService().hasStoragePermission()) &&
                  (await PermissionsService().hasMicrophonePermission())) {
                Navigator.of(context).push(CustomModal(
                  child: _headphonesDialog(),
                ));
              }
              if (!await PermissionsService().hasStoragePermission()) {
                await PermissionsService().requestStoragePermission();
              }
              if (!await PermissionsService().hasMicrophonePermission()) {
                await PermissionsService().requestMicrophonePermission();
              }
            }
          },
          child: Icon(
            recordingStatus == RecordingStatus.Recording
                ? Icons.stop
                : _type == Types.VIDEO ? Icons.videocam : Icons.mic,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget videoRecordingPage() {
    return Stack(
      children: [
        AspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            child: CameraPreview(cameraController)),
        Positioned.fill(
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _recordingTimerText(),
                    SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      onTap: () => saveRecord(),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54,
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset:
                                  Offset(0, 2), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.stop,
                          size: 35,
                          color: MyColors.primaryColor,
                        ),
                      ),
                    )
                  ],
                ))),
      ],
    );
  }

  Widget mainPage() {
    return Container(
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RegularAppbar(context),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  CachedImage(
                    width: 100,
                    height: 100,
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
                            Navigator.of(context).pushReplacementNamed(
                                '/melody-page',
                                arguments: {'melody': widget.melody});
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
                height: 10,
              ),
              Text(
                widget.melody.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(
                height: 10,
              ),
              recordingStatus != RecordingStatus.Recording
                  ? melodyPlayer
                  : _recordingTimerText(),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                height: 150,
                child: SingleChildScrollView(
                  child: Center(
                    child: HtmlWidget(
                      widget.melody.lyrics,
                      textStyle:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      customStylesBuilder: (e) {
                        return {
                          'text-align': 'center',
                          'color': 'white',
                          'line-height': '85%'
                        };
                      },
                    ),
                  ),
                ),
              ),
              // InkWell(
              //   onTap: () async {
              //     if (recordingStatus == RecordingStatus.Recording) {
              //       await saveRecord();
              //     } else {
              //       if ((await PermissionsService().hasStoragePermission()) &&
              //           (await PermissionsService().hasMicrophonePermission())) {
              //         Navigator.of(context).push(CustomModal(
              //           child: _headphonesDialog(),
              //         ));
              //       }
              //       if (!await PermissionsService().hasStoragePermission()) {
              //         await PermissionsService().requestStoragePermission();
              //       }
              //       if (!await PermissionsService().hasMicrophonePermission()) {
              //         await PermissionsService().requestMicrophonePermission();
              //       }
              //     }
              //   },
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: Colors.grey.shade300,
              //       shape: BoxShape.circle,
              //       boxShadow: [
              //         BoxShadow(
              //           color: Colors.black54,
              //           spreadRadius: 4,
              //           blurRadius: 6,
              //           offset: Offset(0, 3), // changes position of shadow
              //         ),
              //       ],
              //     ),
              //     child: Padding(
              //       padding: const EdgeInsets.all(15.0),
              //       child: Icon(
              //         recordingStatus == RecordingStatus.Recording
              //             ? Icons.stop
              //             : _type == Types.VIDEO ? Icons.videocam : Icons.mic,
              //         color: MyColors.primaryColor,
              //         size: 30,
              //       ),
              //     ),
              //   ),
              // ),
              SizedBox(height: 10)
            ],
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
            padding: const EdgeInsets.only(top: 80, left: 10),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Views: ${widget.melody.views ?? 0}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )),
          Positioned.fill(
              child: Padding(
            padding: const EdgeInsets.only(top: 70, right: 10),
            child: Align(
              alignment: Alignment.topRight,
              child: DropdownButton(
                dropdownColor: MyColors.lightPrimaryColor,
                iconEnabledColor: Colors.white,
                style: TextStyle(color: Colors.white, fontSize: 16),
                value: _type,
                items: [
                  DropdownMenuItem(
                    child: Text('Audio'),
                    value: Types.AUDIO,
                  ),
                  DropdownMenuItem(
                    child: Text('Video'),
                    value: Types.VIDEO,
                  ),
                ],
                onChanged: (type) {
                  setState(() {
                    _type = type;
                  });
                },
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget progressPage() {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.primaryColor,
        image: DecorationImage(
          colorFilter: new ColorFilter.mode(
              Colors.black.withOpacity(0.1), BlendMode.dstATop),
          image: AssetImage(Strings.default_melody_page_bg),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: LinearPercentIndicator(
              width: MediaQuery.of(context).size.width - 40,
              lineHeight: 24.0,
              percent: _progress,
              backgroundColor: Colors.grey,
              progressColor: MyColors.primaryColor,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            '${(_progress * 100).toStringAsFixed(2)}%',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(
            height: 15,
          ),
          Text(
            'Please wait this may take some time.',
            style: TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  _recordingTimer() {
    const oneSec = const Duration(seconds: 1);
    num counter = 0;
    Timer.periodic(
      oneSec,
      (timer) {
        if (_type == Types.AUDIO) {
          if (counter >= _duration ||
              recordingStatus == RecordingStatus.Stopped) {}
        } else {
          if (counter >= _duration &&
              recordingStatus == RecordingStatus.Recording) {
            saveRecord();
            counter = 0;
            timer.cancel();
          }
        }

        counter++;
        if (mounted) {
          setState(() {
            _recordingText =
                '${(counter % 60).toInt()} : ${counter ~/ 60} / ${_duration % 60} : ${_duration ~/ 60}';
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

  void _initCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    cameraController = CameraController(cameras[1], ResolutionPreset.medium,
        enableAudio: true);
    await cameraController.initialize();
  }

  Future<bool> _onBackPressed() {
    if (recordingStatus != RecordingStatus.Recording) {
      Navigator.of(context).pop();
    }
  }
}
