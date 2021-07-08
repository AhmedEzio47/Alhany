import 'dart:async';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:record/record.dart';

class NewRecorder {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer _timer;
  final _audioRecorder = Record();
  get isRecording => _audioRecorder.isRecording();

  startRecording() async {
    await AppUtil.createAppDirectory();
    String customPath = appTempDirectoryPath;
    // can add extension like ".mp4" ".wav" ".m4a" ".aac"
    customPath =
        customPath + DateTime.now().millisecondsSinceEpoch.toString() + '.mp3';
    _audioRecorder.start(
      path: customPath,
      // encoder: AudioEncoder.AAC,
      // samplingRate: 44100,
    );
  }

  stopRecording() async {
    await _audioRecorder.stop();
  }
}
