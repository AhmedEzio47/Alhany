import 'dart:async';

import 'package:Alhany/constants/strings.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// class AudioRecorder {
//   FlutterSoundRecorder _recorder;
//   //Recording _recording;
//   get recorderState => _recorder.recorderState;
//   Timer timer;
//   FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
//   FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
//   bool _mPlayerIsInited = false;
//   bool _mRecorderIsInited = false;
//
//   void init() async {
//
//
//     // .wav <---> AudioFormat.WAV
//     // .mp4 .m4a .aac <---> AudioFormat.AAC
//     // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
//
//     _mPlayer.openAudioSession().then((value) {
//
//     });
//
//
//     _recorder = FlutterSoundRecorder();
//     await _recorder.openAudioSession();
//   }
//
//   Future startRecording() async {
//     await init();
//
//     String customPath = appTempDirectoryPath;
//     // can add extension like ".mp4" ".wav" ".m4a" ".aac"
//     customPath = customPath + 'record.aac';
//     print('Start Recording using Flutter_sounds');
//     await _recorder.startRecorder(toFile: customPath);
//
//     // var current = await _recorder.current();
//     //
//     // _recording = current;
//     //
//     // Timer.periodic(Duration(milliseconds: 10), (Timer t) async {
//     //   var current = await _recorder.current();
//     //
//     //   _recording = current;
//     //   timer = t;
//     // });
//   }
//
//   Future<String> stopRecording() async {
//     // if (timer != null) {
//     //   timer.cancel();
//     // }
//     String result = await _recorder.stopRecorder();
//     await _recorder.closeAudioSession();
//     //_recording = result;
//     return result;
//   }
//
//   Future dispose() async {}
// }



typedef _Fn = void Function();

/// Example app.
class AudioRecorder {
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  bool _mRecorderIsInited = false;
  final String _mPath = 'flutter_sound_example.aac';
  get recorderState => _mRecorder.recorderState;

  AudioRecorder(){
    openTheRecorder().then((value) {
      _mRecorderIsInited = true;

    });
  }
  void dispose() {
    _mPlayer.closeAudioSession();
    //_mPlayer = null;

    _mRecorder.closeAudioSession();
    //_mRecorder = null;
  }
  Future<void> openTheRecorder() async {
    await _mRecorder.openAudioSession();
    _mRecorderIsInited = true;
  }
  startRecording() {
    _mRecorder
        .startRecorder(
      toFile: _mPath,
      //codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
    )
        .then((value) {
    });
  }

  Future<String?> stopRecording() async {
    String? result = await _mRecorder.stopRecorder();
    dispose();

    return result;
  }
// _Fn getRecorderFn() {
//   if (!_mRecorderIsInited || !_mPlayer.isStopped) {
//     return null;
//   }
//   return _mRecorder.isStopped ? record : stopRecorder;
// }
}



