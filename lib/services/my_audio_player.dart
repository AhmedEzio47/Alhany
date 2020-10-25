import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dubsmash/pages/melody_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';

class MyAudioPlayer with ChangeNotifier {
  AudioPlayer advancedPlayer = AudioPlayer();
  AudioCache audioCache;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  Duration duration;
  Duration position;

  final String url;
  final Function onComplete;
  final bool isLocal;

  MyAudioPlayer({@required this.url, this.isLocal = false, this.onComplete}) {
    initAudioPlayer();
  }

  initAudioPlayer() {
    advancedPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: advancedPlayer);

    advancedPlayer.durationHandler = (d) {
      duration = d;
      notifyListeners();
      // print('my duration:$duration');
    };

    advancedPlayer.positionHandler = (p) {
      position = p;
      notifyListeners();
      //print('d:${duration.inMilliseconds} - p:${p.inMilliseconds}');
      if (duration.inMilliseconds - p.inMilliseconds < 200) {
        stop();
      }
    };
  }

  Future play() async {
    print('audio url: $url');
    await advancedPlayer.play(url, isLocal: isLocal);
    playerState = AudioPlayerState.PLAYING;
    notifyListeners();
  }

  Future stop() async {
    await advancedPlayer.stop();
    playerState = AudioPlayerState.STOPPED;
    position = null;
    duration = null;
    notifyListeners();
    if (onComplete != null && MelodyPage.recordingStatus == RecordingStatus.Recording) {
      onComplete();
    }
  }

  Future pause() async {
    await advancedPlayer.pause();
    playerState = AudioPlayerState.PAUSED;
    notifyListeners();
  }

  seek(Duration p) {
    advancedPlayer.seek(p);
    notifyListeners();
  }
}
