import 'dart:async';
import 'package:dubsmash/pages/melody_page.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';

class AudioRecorder {
  FlutterAudioRecorder _recorder;
  Recording _recording;
  Timer timer;

  AudioRecorder() {
    init();
  }

  void init() async {
    String customPath = '/sdcard/download/';

    // can add extension like ".mp4" ".wav" ".m4a" ".aac"
    customPath = customPath + DateTime.now().millisecondsSinceEpoch.toString();

    // .wav <---> AudioFormat.WAV
    // .mp4 .m4a .aac <---> AudioFormat.AAC
    // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.

    _recorder = FlutterAudioRecorder(customPath,
        audioFormat: AudioFormat.WAV, sampleRate: 22050);
    await _recorder.initialized;
  }

  Future startRecording({var conversation}) async {
    await _recorder.start();
    var current = await _recorder.current();

    _recording = current;

    Timer.periodic(Duration(milliseconds: 10), (Timer t) async {
      var current = await _recorder.current();

      _recording = current;
      timer = t;
    });
  }

  Future stopRecording() async {
    timer.cancel();
    var result = await _recorder.stop();
    _recording = result;
    return result;
  }
}
