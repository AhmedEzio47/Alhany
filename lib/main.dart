import 'dart:io';

import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/services/auth.dart';
import 'package:dubsmash/services/auth_provider.dart';
import 'package:dubsmash/services/route_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:video_player/video_player.dart';

import 'app_util.dart';
import 'services/audio_recorder.dart';
import 'services/permissions_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      auth: Auth(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: MyColors.primaryColor,
          primaryColorDark: MyColors.darkPrimaryColor,
          primaryColorLight: MyColors.lightPrimaryColor,
          brightness: Brightness.light,
        ),
//      home: MyHomePage(title: 'Flutter Demo Home Page'),
        initialRoute: '/',
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  AudioRecorder recorder;
  bool isMicrophoneGranted = false;
  var _currentStatus;

  String recordingFilePath;
  String selectedVideoPath = '/sdcard/Download/Criminal.mp4';
  String mergedFilePath = '/sdcard/Download/Criminal_new.mp4';

  VideoPlayerController _controller;

  initVideoPlayer() async {
    if (!await PermissionsService().hasStoragePermission()) {
      PermissionsService().requestStoragePermission();
    }
    _controller = VideoPlayerController.file(File(selectedVideoPath))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  FlutterFFmpeg flutterFFmpeg;
  @override
  void initState() {
    flutterFFmpeg = FlutterFFmpeg();
    initVideoPlayer();
    super.initState();
  }

  void _record() async {
    if (await PermissionsService().hasMicrophonePermission()) {
      setState(() {
        isMicrophoneGranted = true;
      });
    } else {
      bool isGranted = await PermissionsService().requestMicrophonePermission(
          onPermissionDenied: () {
        AppUtil.alertDialog(
            context,
            'info',
            'You must grant this microphone access to be able to use this feature.',
            'OK');
        print('Permission has been denied');
      });
      setState(() {
        isMicrophoneGranted = isGranted;
      });
      return;
    }

    if (isMicrophoneGranted) {
      if (_currentStatus == RecordingStatus.Recording) {
        await _controller.pause();
        setState(() {
          _currentStatus = RecordingStatus.Stopped;
        });
        Recording result = await recorder.stopRecording();
        recordingFilePath = result.path;
        int success = await flutterFFmpeg.execute(
            "-y -i $recordingFilePath -i $selectedVideoPath -map 0:a -map 1:v  -shortest $mergedFilePath");
        print(success == 1 ? 'Failure!' : 'Success!');
      }
      setState(() {
        _controller.value.isPlaying ? _controller.pause() : _controller.play();
      });

      setState(() {
        _currentStatus = RecordingStatus.Recording;
      });
      await initRecorder();
      _controller.play();
      await recorder.startRecording(conversation: this.widget);
    } else {}
  }

  initRecorder() async {
    recorder = AudioRecorder();
    recordingFilePath = await recorder.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _controller.value.initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _record,
        tooltip: 'Record',
        child: Icon(_controller.value.isPlaying ? Icons.stop : Icons.mic),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
