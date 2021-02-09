import 'dart:async';

import 'package:sounds/sounds.dart';

enum RecordingStatus { Recording, Stopped, Unset }

class AudioRecorder {
  SoundRecorder _recorder;
  String _recording;
  Timer timer;
  Track _track;

  AudioRecorder() {
    init();
  }

  void init() async {
    // String customPath = appTempDirectoryPath;
    // customPath = customPath + DateTime.now().millisecondsSinceEpoch.toString();

    _recording = Track.tempFile(WellKnownMediaFormats.adtsAac);

    _recorder = SoundRecorder();

    _track =
        Track.fromFile(_recording, mediaFormat: WellKnownMediaFormats.adtsAac);

    _recorder.onStopped = ({wasUser}) async {
      await _recorder.release();

      /// recording has finished so play it back to the user.
      print(_recording);
      //File(_recording).delete();
    };
  }

  Future startRecording() async {
    await _recorder.record(_track);
    //var current = await _recorder.current();

    //_recording = current;

    // Timer.periodic(Duration(milliseconds: 10), (Timer t) async {
    //   var current = await _recorder.current();
    //
    //   _recording = current;
    //   timer = t;
    // });
  }

  Future<String> stopRecording() async {
    await _recorder.stop();
    return _recording;
  }

  dispose() async {
    //await _recorder.release();
  }
}
