import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';

class MyAudioPlayer with ChangeNotifier {
  AudioPlayer advancedPlayer = AudioPlayer();
  AudioCache audioCache;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  Duration duration;
  Duration position;

  final String url;
  final List<String> urlList;
  final Function onComplete;
  final bool isLocal;

  MyAudioPlayer({@required this.url, this.urlList, this.isLocal = false, this.onComplete}) {
    initAudioPlayer();
  }

  int _index = 0;

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
        if (urlList != null) {
          play(index: ++_index);
        } else {
          stop();
        }
      }
    };
  }

  Future play({index}) async {
    print('audio url: $url');
    if (index == null) {
      index = _index;
    }
    await advancedPlayer.play(url ?? urlList[index], isLocal: isLocal);
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

  next() {
    advancedPlayer.stop();
    if (_index < urlList.length - 1)
      _index++;
    else
      _index = 0;
    play(index: _index);
  }

  prev() {
    advancedPlayer.stop();
    if (_index > 0)
      _index--;
    else
      _index = urlList.length - 1;
    play(index: _index);
  }
}
