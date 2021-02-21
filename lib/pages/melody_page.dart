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
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:flutter_ffmpeg/statistics.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:path/path.dart' as path;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
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
  //
  // FlutterFFmpeg flutterFFmpeg;

  String _dropdownValue;

  String _recordingText = '';

  int _duration;

  video_player.VideoPlayerController _videoController;

  bool _isVideoPlaying = false;

  File _image;

  final FlutterFFmpegConfig _flutterFFmpegConfig = new FlutterFFmpegConfig();
  final FlutterFFmpeg flutterFFmpeg = new FlutterFFmpeg();
  final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    if (await PermissionsService().hasMicrophonePermission()) {
      setState(() {
        isMicrophoneGranted = true;
      });
    } else {
      bool isGranted = await PermissionsService()
          .requestMicrophonePermission(context, onPermissionDenied: () async {
        PermissionStatus status = await PermissionsService()
            .checkPermissionStatus(PermissionGroup.microphone);

        if (status == PermissionStatus.neverAskAgain) {
          AppUtil.showAlertDialog(
              context: context,
              message:
              'You have chosen to never ask for this permission again, please go to settings and choose permissions to allow this.',
              firstBtnText: 'Go to settings',
              firstFunc: () {
                Navigator.of(context).pop();
                PermissionHandler().openAppSettings();
                return;
              },
              secondBtnText: 'Cancel',
              secondFunc: () {
                Navigator.of(context).pop();
              });
        } else if (status == PermissionStatus.denied)
          AppUtil.showAlertDialog(
            context: context,
            heading: 'info',
            message:
            'You must grant this microphone access to be able to use this feature.',
            firstBtnText: 'Give Permission',
            firstFunc: () async {
              Navigator.of(context).pop(false);
              await _recordAudio();
            },
            secondBtnText: 'Leave',
            secondFunc: () async {
              print('Mic permission denied');
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );
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
      myAudioPlayer =
          MyAudioPlayer(url: melodyPath, onComplete: saveRecord, isLocal: true);
      myAudioPlayer.addListener(() {});

      await myAudioPlayer.play(onPlayingStarted: () async {
        try {
          await recorder.startRecording();
        } catch (ex) {
          await myAudioPlayer.stop();
          AppUtil.showToast('Unexpected error. Please try again.');
          Navigator.of(context).pop();
        }
      });

      _recordingTimer();
    } else {}
  }

  CameraController cameraController;
  Future<void> _initializeControllerFuture;

  void _recordVideo() async {
    if (await PermissionsService().hasMicrophonePermission()) {
      setState(() {
        isMicrophoneGranted = true;
      });
    } else {
      bool isGranted = await PermissionsService()
          .requestMicrophonePermission(context, onPermissionDenied: () async {
        PermissionStatus status = await PermissionsService()
            .checkPermissionStatus(PermissionGroup.microphone);

        if (status == PermissionStatus.neverAskAgain) {
          AppUtil.showAlertDialog(
              context: context,
              message:
              'You have chosen to never ask for this permission again, please go to settings and choose permissions to allow this.',
              firstBtnText: 'Go to settings',
              firstFunc: () {
                Navigator.of(context).pop();
                PermissionHandler().openAppSettings();
                return;
              },
              secondBtnText: 'Cancel',
              secondFunc: () {
                Navigator.of(context).pop();
              });
        } else if (status == PermissionStatus.denied)
          AppUtil.showAlertDialog(
            context: context,
            heading: 'info',
            message:
            'You must grant this microphone access to be able to use this feature.',
            firstBtnText: 'Give Permission',
            firstFunc: () async {
              Navigator.of(context).pop(false);
              await _recordVideo();
            },
            secondBtnText: 'Leave',
            secondFunc: () async {
              print('Mic permission denied');
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );
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
      myAudioPlayer =
          MyAudioPlayer(url: melodyPath, onComplete: saveRecord, isLocal: true);
      myAudioPlayer.addListener(() {});

      recordingFilePath += 'video_rec.mp4';
      try {
        File(recordingFilePath).deleteSync();
      } catch (e) {}

      if (cameraController == null) {
        await _initCamera();
      }

      await myAudioPlayer.play();
      try {
        await _initializeControllerFuture;
        await cameraController.startVideoRecording(recordingFilePath);
      } catch (ex) {
        AppUtil.showToast('Unexpected error, please try again');
        Navigator.of(context).pop();
      }

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
                        color: MyColors.textDarkColor,
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
                          color: MyColors.textDarkColor,
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
    setState(() {
      recordingStatus = RecordingStatus.Stopped;
    });
    MelodyPage.recordingStatus = RecordingStatus.Stopped;

    await myAudioPlayer.stop();

    try {
      if (_type == Types.AUDIO) {
        String result = await recorder.stopRecording();
        recordingFilePath = result;
        String url = await AppUtil().uploadFile(File(recordingFilePath),
            context, 'tests/test${path.extension(recordingFilePath)}');
        print('test url:' + url);
      } else {
        await cameraController.stopVideoRecording();
      }
    } catch (ex) {
      AppUtil.showToast('Unknown error, please try again.');
      Navigator.of(context).pop();
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
      /*
      success = await flutterFFmpeg.execute(
          "-i $recordingFilePath -ac 2 -filter:a \"volume=${Constants.voiceVolume}\" ${appTempDirectoryPath}stereo_audio.wav");
      print(success == 1 ? 'TO STEREO Failure!' : 'TO STEREO Success!');
      MediaInformation info =
      await _flutterFFprobe.getMediaInformation(melodyPath);
      _flutterFFmpegConfig.enableStatisticsCallback(this.statisticsCallback);
      _recordingDuration = double.parse(info.getMediaProperties()['duration']);
      if (mounted) {
        setState(() {
          _progressVisible = true;
        });
      }
      success = await flutterFFmpeg.execute(
          "-i $melodyPath -filter:a \"volume=${Constants.musicVolume}\" ${appTempDirectoryPath}decreased_music.mp3");
      print(success == 1 ? 'TO STEREO Failure2!' : 'TO STEREO Success2!');
*/
      // success = await flutterFFmpeg.execute(
      //     '-i ${appTempDirectoryPath}decreased_music.mp3 -af "adelay=1s:all=true" ${appTempDirectoryPath}added_silence.mp3');
      // print(success == 1
      //     ? 'Added 1 s silence Failure!'
      //     : 'Added 1 s silence Success!');

      MediaInformation info =
      await _flutterFFprobe.getMediaInformation('$recordingFilePath');
      _flutterFFmpegConfig.enableStatisticsCallback(this.statisticsCallback);
      _recordingDuration = double.parse(info.getMediaProperties()['duration']);

      if (mounted) {
        setState(() {
          _progressVisible = true;
        });
      }
      //MERGE 2 sounds
      success = await flutterFFmpeg.execute(
          "-i $recordingFilePath -i $melodyPath -filter_complex amix=inputs=2:weights=\"7 0.4\":duration=first:dropout_transition=1 $mergedFilePath");
      print(success == 1 ? 'Failure!' : 'Success!');
      setState(() {
        _progressVisible = false;
      });
    } else {
      //STEP 1: EXTRACT AUDIO FROM VIDEO
      //AppUtil.showLoader(context);
      AppUtil.showFixedSnackBar(
          context,
          _scaffoldKey,
          language(
              en: 'Please hold on, it\'s not stuck',
              ar: 'برجاء الإنتظار جاري معالجة الفيديو'));
      success = await flutterFFmpeg.execute(
          '-i $recordingFilePath -ac 2 -filter:a \"volume=3.5\" ${appTempDirectoryPath}extracted_audio.mp3');
      print(success == 1 ? 'EXTRACT Failure!' : 'EXTRACT Success!');

      success = await flutterFFmpeg.execute(
          '-i $melodyPath -af "adelay=700:all=true" ${appTempDirectoryPath}added_silence.mp3');
      print(success == 1
          ? 'Added 1 s silence Failure!'
          : 'Added 1 s silence Success!');

      //Navigator.of(context).pop();
      //STEP 2:MERGE BOTH MELODY AND EXTRACTED AUDIO
      success = await flutterFFmpeg.execute(
          "-y -i ${appTempDirectoryPath}extracted_audio.mp3 -i ${appTempDirectoryPath}added_silence.mp3 -filter_complex amerge=inputs=2 -shortest ${appTempDirectoryPath}final_audio.mp3");

      _scaffoldKey.currentState?.removeCurrentSnackBar();

      MediaInformation info = await _flutterFFprobe
          .getMediaInformation('${appTempDirectoryPath}final_audio.mp3');
      _flutterFFmpegConfig.enableStatisticsCallback(this.statisticsCallback);
      _recordingDuration = double.parse(info.getMediaProperties()['duration']);
      print(success == 1 ? 'MERGE Failure!' : 'MERGE Success!');

      if (mounted) {
        setState(() {
          _progressVisible = true;
        });
      }
      // MERGE VIDEO WITH FINAL AUDIO
      success = await flutterFFmpeg.execute(
          "-y -i ${appTempDirectoryPath}final_audio.mp3 -i $recordingFilePath -map 0:a -map 1:v -shortest ${appTempDirectoryPath}final_video.mp4");
      print(success == 1 ? 'FINAL Failure!' : 'FINAL Success!');

      //Scale video
      success = await flutterFFmpeg.execute(
          "-i ${appTempDirectoryPath}final_video.mp4 -filter:v scale=720:-1 -c:a copy $mergedFilePath");
      print(success == 1 ? 'FINAL Failure!' : 'FINAL Success!');

      success = await flutterFFmpeg.execute(
          "-y -i $mergedFilePath -ss 00:00:01.000 -vframes 1 ${appTempDirectoryPath}thumbnail.png");
      print(success == 1 ? 'THUMBNAIL Failure!' : 'THUMBNAIL Success!');
      setState(() {
        _progressVisible = false;
      });
    }
    int duration;
    try {
      MediaInformation info =
      await _flutterFFprobe.getMediaInformation(mergedFilePath);
      duration = double.parse(info.getMediaProperties()['duration'].toString())
          .toInt();
    } catch (error) {
      duration = 0;
    }

    if (_type == Types.AUDIO) {
      melodyPlayer = MusicPlayer(
        key: ValueKey('preview'),
        url: mergedFilePath,
        isLocal: true,
        backColor: MyColors.primaryColor,
        initialDuration: duration,
      );
    } else {
      await initVideoPlayer();
    }

    setState(() {
      choosingImage = true;
    });

    print(success == 1 ? 'Failure!' : 'Success!');
  }

  bool choosingImage = false;

  void statisticsCallback(Statistics statistics) {
    try {
      double progress = statistics.time / (_recordingDuration * 1000);

      setState(() {
        if (progress > 1)
          _progress = 1;
        else if (progress < 0)
          _progress = 0;
        else if (progress >= 0 && progress <= 1) _progress = progress;
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
        :
    // : InkWell(
    //     onTap: _videoController.value.isPlaying
    //         ? () => setState(() {
    //               _isVideoPlaying = false;
    //               _videoController.pause();
    //             })
    //         : null,
    //     child: Container(
    //       height: 40,
    //       width: 40,
    //       decoration: BoxDecoration(
    //         shape: BoxShape.circle,
    //         color: Colors.grey.shade300,
    //         boxShadow: [
    //           BoxShadow(
    //             color: Colors.black54,
    //             spreadRadius: 2,
    //             blurRadius: 4,
    //             offset: Offset(0, 2), // changes position of shadow
    //           ),
    //         ],
    //       ),
    //       child: Icon(
    //         Icons.pause,
    //         color: MyColors.primaryColor,
    //         size: 35,
    //       ),
    //     ),
    //   );
    Container();
  }

  bool isStoragePermissionGranted = false;
  createAppFolder() async {
    if (await PermissionsService().hasStoragePermission()) {
      setState(() {
        isStoragePermissionGranted = true;
      });
      print('storage permission granted');
    } else {
      bool isGranted = await PermissionsService()
          .requestStoragePermission(context, onPermissionDenied: () async {
        PermissionStatus status = await PermissionsService()
            .checkPermissionStatus(PermissionGroup.storage);

        if (status == PermissionStatus.neverAskAgain) {
          AppUtil.showAlertDialog(
              context: context,
              message:
              'You have chosen to never ask for this permission again, please go to settings and choose permissions to allow this.',
              firstBtnText: 'Go to settings',
              firstFunc: () {
                Navigator.of(context).pop();
                PermissionHandler().openAppSettings();
                return;
              },
              secondBtnText: 'Cancel',
              secondFunc: () {
                Navigator.of(context).pop();
              });
        } else if (status == PermissionStatus.denied)
          AppUtil.showAlertDialog(
            context: context,
            heading: 'info',
            message:
            'You must grant this storage access to be able to use this feature.',
            firstBtnText: 'Give Permission',
            firstFunc: () async {
              Navigator.of(context).pop(false);
              await createAppFolder();
            },
            secondBtnText: 'Leave',
            secondFunc: () async {
              print('storage permission denied');
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );

        print('storage permission denied');
      });
      setState(() {
        isStoragePermissionGranted = isGranted;
      });
      return;
    }

    if (isStoragePermissionGranted) {
      print('deleting temp files then creating an empty folder...');
      await AppUtil.deleteFiles();
      await AppUtil.createAppDirectory();
    }
  }

  double _progress = 0;
  submitRecord() async {
    AppUtil.showLoader(context);
    setState(() {
      _progressVisible = true;
    });
    String recordId = randomAlphaNumeric(20);
    String url, thumbnailUrl;
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
    if (_type == Types.VIDEO) {
      thumbnailUrl = await appUtil.uploadFile(
          File('${appTempDirectoryPath}thumbnail.png'),
          context,
          'records_thumbnails/${widget.melody.id}/$recordId${path.extension('${appTempDirectoryPath}thumbnail.png')}');
    } else {
      thumbnailUrl = await appUtil.uploadFile(File(_image.path), context,
          'records_thumbnails/${widget.melody.id}/$recordId${path.extension(_image.path)}');
    }

    if (mounted) {
      setState(() {
        _progressVisible = false;
      });
    }
    //AppUtil.showLoader(context);
    MediaInformation info = await _flutterFFprobe.getMediaInformation(
        _type == Types.VIDEO ? mergedFilePath : imageVideoPath);
    int duration =
    double.parse(info.getMediaProperties()['duration'].toString()).toInt();

    await DatabaseService.submitRecord(
        widget.melody.id, recordId, url, thumbnailUrl, duration);
    await AppUtil.deleteFiles();
    Navigator.of(context).pop();

    AppUtil.showToast('Submitted!');
  }

  initRecorder() async {
    //await AppUtil.createAppDirectory();
    recordingFilePath = appTempDirectoryPath;
    recorder = AudioRecorder();
  }

  initVideoPlayer() async {
    if (!await PermissionsService().hasStoragePermission()) {
      PermissionsService().requestStoragePermission(
        context,
      );
    }
    PermissionStatus status = await PermissionsService()
        .checkPermissionStatus(PermissionGroup.storage);

    if (status == PermissionStatus.neverAskAgain) {
      AppUtil.showAlertDialog(
          context: context,
          message:
          'You have chosen to never ask for this permission again, please go to settings and choose permissions to allow this.',
          firstBtnText: 'Go to settings',
          firstFunc: () {
            Navigator.of(context).pop();
            PermissionHandler().openAppSettings();
            return;
          },
          secondBtnText: 'Cancel',
          secondFunc: () {
            Navigator.of(context).pop();
          });
    }
    _videoController =
        video_player.VideoPlayerController.file(File(mergedFilePath));
    await _videoController.initialize();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _type = widget.type;
    });

    DatabaseService.incrementMelodyViews(widget.melody.id);
    if (widget.melody.levelUrls != null) {
      _dropdownValue = widget.melody.levelUrls.keys.elementAt(0);
    }
    prepareEnv();
  }

  prepareEnv() async {
    await createAppFolder();

    if (widget.melody.audioUrl != null) {
      await initMelodyPlayer(widget.melody.audioUrl);
    } else if (Constants.currentMelodyLevel != null) {
      await initMelodyPlayer(
          widget.melody.levelUrls[Constants.currentMelodyLevel]);
    } else {
      await initMelodyPlayer(
          widget.melody.levelUrls.values.elementAt(0).toString());
    }

    if (_type == Types.VIDEO) {
      await _initCamera();
    }
  }

  @override
  dispose() {
    if (_videoController != null) {
      _videoController.dispose();
    }

    print('trying to dispose camera');
    if (cameraController != null) {
      print('disposing camera');
      cameraController.dispose();
      print('camera disposed');
    }
    recorder.dispose();
    super.dispose();
  }

  initMelodyPlayer(String url) async {
    setState(() {
      melodyPlayer = new MusicPlayer(
        key: ValueKey('main'),
        url: url,
        isRecordBtnVisible: false,
        backColor: Colors.transparent,
        initialDuration: widget.melody.duration,
        melody: widget.melody,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        body: choosingImage
            ? choosingImagePage(context)
            : _progressVisible
            ? progressPage()
            : recordingStatus == RecordingStatus.Recording &&
            _type == Types.VIDEO
            ? videoRecordingPage()
            : mainPage(),
        floatingActionButton: !_progressVisible && !choosingImage
            ? FloatingActionButton(
          onPressed: () async {
            if (recordingStatus == RecordingStatus.Recording) {
              await saveRecord();
            } else {
              if ((await PermissionsService().hasStoragePermission()) &&
                  (await PermissionsService()
                      .hasMicrophonePermission())) {
                await createAppFolder();
                //await AppUtil.createAppDirectory();
                recordingFilePath = appTempDirectoryPath;
                melodyPath = appTempDirectoryPath;
                mergedFilePath = appTempDirectoryPath;
                await _downloadMelody();

                Navigator.of(context).push(CustomModal(
                  child: _headphonesDialog(),
                ));
              }
              if (!await PermissionsService().hasStoragePermission()) {
                await PermissionsService().requestStoragePermission(
                  context,
                );
              }
              if (!await PermissionsService().hasMicrophonePermission()) {
                await PermissionsService().requestMicrophonePermission(
                  context,
                );
              }
            }
          },
          child: Icon(
            recordingStatus == RecordingStatus.Recording
                ? Icons.stop
                : _type == Types.VIDEO
                ? Icons.videocam
                : Icons.mic,
            color: MyColors.primaryColor,
            size: 30,
          ),
        )
            : null,
      ),
    );
  }

  bool _isPreviewVideoPlaying = false;
  choosingImagePage(BuildContext context) {
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
      child: Center(
        child: Container(
          child: _type == Types.AUDIO
              ? SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                melodyPlayer ?? Container(),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RaisedButton(
                      onPressed: imageVideoPath == null
                          ? () async {
                        _image = await AppUtil
                            .pickCompressedImageFromGallery();
                        // FileStat s = await pickedImage.stat();
                        //
                        // print('Non-Compressed file: ${s.size}');
                        //
                        // _image = await FlutterImageCompress
                        //     .compressAndGetFile(
                        //   pickedImage.absolute.path,
                        //   '$appTempDirectoryPath/${path.basename(pickedImage.absolute.path)}',
                        //   quality: 50,
                        // );
                        //
                        // s = await _image.stat();
                        // print('Compressed file size: ${s.size}');

                        setState(() {
                          imageVideoPath =
                          '${path.withoutExtension(mergedFilePath)}.mp4';
                        });
                        setState(() {
                          _progressVisible = true;
                          choosingImage = false;
                        });
                        _flutterFFmpegConfig
                            .enableStatisticsCallback(
                            this.statisticsCallback);
                        print(
                            'mergedFilePath + $mergedFilePath + _image.path + ${_image.path} + imageVideoPath + $imageVideoPath');
                        int success = await flutterFFmpeg.execute(
                            "-loop 1 -i ${_image.path} -i $mergedFilePath -vf \"scale=720:-1,format=yuv420p\" -c:v libx264 -preset medium -profile:v main -c:a aac -shortest -movflags +faststart $imageVideoPath");
                        print('conversion success:$success');
                        if (success != 0) {
                          AppUtil.showToast(
                              'Unexpected error, please try another image');
                          Navigator.of(context).pop();
                          return;
                        }

                        if (_image == null) {
                          AppUtil.showToast(language(
                              en: 'Please choose an image',
                              ar: 'من فضلك اختر صورة'));
                          return;
                        }
                        setState(() {
                          choosingImage = false;
                          _progressVisible = true;
                        });
                        await submitRecord();
                        setState(() {
                          _progressVisible = false;
                        });
                        Navigator.pushNamedAndRemoveUntil(
                            context, "/", (r) => false);
                        // setState(() {
                        //   _progressVisible = false;
                        //   choosingImage = true;
                        // });
                      }
                          : null,
                      color: MyColors.primaryColor,
                      child: Text(
                        imageVideoPath == null
                            ? 'Choose Image & Submit'
                            : 'Done',
                        style: TextStyle(color: MyColors.textLightColor),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    RaisedButton(
                      onPressed: () async {
                        await AppUtil.deleteFiles();
                        Navigator.of(context).pop();
                      },
                      color: MyColors.primaryColor,
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: MyColors.textLightColor),
                      ),
                    ),
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
                  child: Align(
                    child: playPauseBtn(),
                    alignment: Alignment.center,
                  )),
              Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RaisedButton(
                            onPressed: () async {
                              //Navigator.of(context).pop(false);
                              await submitRecord();
                              Navigator.pushNamedAndRemoveUntil(
                                  context, "/", (r) => false);
                            },
                            color: MyColors.primaryColor,
                            child: Text(
                              'Submit',
                              style:
                              TextStyle(color: MyColors.textLightColor),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          RaisedButton(
                            onPressed: () async {
                              await _videoController.pause();
                              await AppUtil.deleteFiles();
                              Navigator.of(context).pop();
                            },
                            color: MyColors.primaryColor,
                            child: Text(
                              'Cancel',
                              style:
                              TextStyle(color: MyColors.textLightColor),
                            ),
                          ),
                        ],
                      ),
                      alignment: Alignment.bottomCenter,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget videoRecordingPage() {
    return Stack(
      children: [
        FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the Future is complete, display the preview.
              return Center(
                child: AspectRatio(
                    aspectRatio: cameraController?.value?.aspectRatio ?? 16 / 9,
                    child: CameraPreview(cameraController)),
              );
            } else {
              // Otherwise, display a loading indicator.
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
              color: Colors.transparent,
              height: 200,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Center(
                  child: HtmlWidget(
                    widget.melody.lyrics ?? '',
                    textStyle:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    customStylesBuilder: (e) {
                      return {'text-align': 'center', 'line-height': '85%'};
                    },
                  ),
                ),
              )),
        )
      ],
    );
  }

  Widget mainPage() {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.primaryColor,
        gradient: new LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            MyColors.primaryColor,
          ],
        ),
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                  alignment: Alignment.topCenter,
                  child: RegularAppbar(
                    context,
                    onBackPressed: _onBackPressed,
                  )),
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
                    iconEnabledColor: MyColors.iconLightColor,
                    style: TextStyle(
                        color: MyColors.textLightColor, fontSize: 16),
                    value: Constants.currentMelodyLevel ?? _dropdownValue,
                    onChanged: (choice) async {
                      Constants.currentMelodyLevel = choice;
                      Navigator.of(context).pushReplacementNamed(
                          '/melody-page',
                          arguments: {
                            'melody': widget.melody,
                          });
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
                    color: MyColors.textLightColor),
              ),
              SizedBox(
                height: 10,
              ),
              recordingStatus != RecordingStatus.Recording
                  ? melodyPlayer ?? Container()
                  : _recordingTimerText(),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width + 50,
                  child: SingleChildScrollView(
                    child: Center(
                      child: HtmlWidget(
                        widget.melody.lyrics ?? '',
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        customStylesBuilder: (e) {
                          return {'text-align': 'center', 'line-height': '85%'};
                        },
                      ),
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
                    style: TextStyle(color: MyColors.textLightColor),
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
                    iconEnabledColor: MyColors.iconLightColor,
                    style: TextStyle(color: MyColors.textLightColor, fontSize: 16),
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
                    onChanged: (type) async {
                      setState(() {
                        _type = type;
                      });
                      print('Type: $_type');
                      if (_type == Types.VIDEO) {
                        await _initCamera();
                      }
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
            style: TextStyle(color: MyColors.textLightColor),
          ),
          SizedBox(
            height: 15,
          ),
          Text(
            'Please wait this may take some time.',
            style: TextStyle(color: MyColors.textLightColor),
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
        //TODO trial
        // if (recordingStatus == RecordingStatus.Stopped) {
        //   timer.cancel();
        // }
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
          try {
            setState(() {
              _recordingText =
              '${(counter ~/ 60).toInt()} : ${counter % 60} / ${_duration ~/ 60} : ${_duration % 60}';
            });
          } catch (ex) {
            timer.cancel();
          }
        }
      },
    );
  }

  Widget _recordingTimerText() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Text(
        _recordingText,
        style: TextStyle(fontSize: 20, color: MyColors.textLightColor),
      ),
    );
  }

  bool isCameraPermissionGranted = false;
  void _initCamera() async {
    if (await PermissionsService().hasCameraPermission()) {
      setState(() {
        isCameraPermissionGranted = true;
      });
      print('camera permission granted');
    } else {
      bool isGranted = await PermissionsService()
          .requestCameraPermission(context, onPermissionDenied: () async {
        PermissionStatus status = await PermissionsService()
            .checkPermissionStatus(PermissionGroup.camera);

        if (status == PermissionStatus.neverAskAgain) {
          AppUtil.showAlertDialog(
              context: context,
              message:
              'You have chosen to never ask for this permission again, please go to settings and choose permissions to allow this.',
              firstBtnText: 'Go to settings',
              firstFunc: () {
                Navigator.of(context).pop();
                PermissionHandler().openAppSettings();
                return;
              },
              secondBtnText: 'Cancel',
              secondFunc: () {
                Navigator.of(context).pop();
              });
        } else if (status == PermissionStatus.denied) {
          AppUtil.showAlertDialog(
            context: context,
            heading: 'info',
            message:
            'You must grant this camera access to be able to use this feature.',
            firstBtnText: 'Give Permission',
            firstFunc: () async {
              Navigator.of(context).pop(false);
              await _initCamera();
            },
            secondBtnText: 'Leave',
            secondFunc: () async {
              print('camera permission denied');
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );
        }
      });
      setState(() {
        isCameraPermissionGranted = isGranted;
      });
      return;
    }

    if (isCameraPermissionGranted) {
      if (cameraController != null) {
        await cameraController.dispose();
      }
      cameras = await availableCameras();
      cameraController = CameraController(cameras[1], ResolutionPreset.medium,
          enableAudio: true);
      print('Camera: $cameraController');
      _initializeControllerFuture = cameraController.initialize();
    }
  }

  Future<bool> _onBackPressed() {
    if (recordingStatus != RecordingStatus.Recording) {
      Navigator.of(context).pop();
    }
  }
}