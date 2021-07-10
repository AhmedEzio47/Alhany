import 'dart:async';

import 'package:Alhany/constants/strings.dart';
import 'package:record/record.dart';

enum RecordingStatus { Unset, Recording, Stopped }

class NewRecorder {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer _timer;
  final _audioRecorder = Record();
  get isRecording => _audioRecorder.isRecording();

  startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String customPath = appTempDirectoryPath;
        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = customPath +
            DateTime.now().millisecondsSinceEpoch.toString() +
            '.mp3';
        _audioRecorder.start(
          path: customPath,
          // encoder: AudioEncoder.AAC,
          // samplingRate: 44100,
        );

        bool isRecording = await _audioRecorder.isRecording();

        _isRecording = isRecording;
        _recordDuration = 0;
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String> stopRecording() async {
    return await _audioRecorder.stop();
  }
}
