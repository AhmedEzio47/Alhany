import 'dart:async';

import 'package:record/record.dart';

enum RecordingStatus { Unset, Recording, Stopped }

class NewRecorder {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer _timer;
  final String path;
  final _audioRecorder = Record();

  NewRecorder(this.path);
  get isRecording => _audioRecorder.isRecording();

  startRecording() async {
    try {
      // can add extension like ".mp4" ".wav" ".m4a" ".aac"
      var customPath =
          path + DateTime.now().millisecondsSinceEpoch.toString() + '.m4a';
      _audioRecorder.start(
        path: customPath,
        // encoder: AudioEncoder.AAC,
        // samplingRate: 44100,
      );

      bool isRecording = await _audioRecorder.isRecording();

      _isRecording = isRecording;
      _recordDuration = 0;
    } catch (e) {
      print(e);
    }
  }

  Future<String> stopRecording() async {
    return await _audioRecorder.stop();
  }
}
