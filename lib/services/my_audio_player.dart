import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/services/audio_recorder.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

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

  MyAudioPlayer(
      {this.url, this.urlList, this.isLocal = false, this.onComplete}) {
    initAudioPlayer();
  }

  int index = 0;

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
      print('P:${p.inMilliseconds}');
      print('D:${duration.inMilliseconds}');
      notifyListeners();

      if (duration.inMilliseconds - p.inMilliseconds <
          Constants.endPositionOffsetInMilliSeconds) {
        stop();
        if (urlList != null) {
          if (this.index < urlList.length - 1)
            this.index++;
          else
            this.index = 0;
          play(index: this.index);
          notifyListeners();
        } else {
          stop();
        }
      } else if (duration.inMilliseconds - p.inMilliseconds == 0) {
        if (urlList != null) {
          if (this.index < urlList.length - 1)
            this.index++;
          else
            this.index = 0;
          play(index: this.index);
          notifyListeners();
        } else {
          stop();
        }
      }
    };
  }

  Future play({index}) async {
    print('audio url: $url');
    if (index == null) {
      index = this.index;
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
    if (onComplete != null &&
        MelodyPage.recordingStatus == RecordingStatus.Recording) {
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
    if (this.index < urlList.length - 1)
      this.index++;
    else
      this.index = 0;
    notifyListeners();
    play(index: this.index);
  }

  prev() {
    advancedPlayer.stop();
    if (this.index > 0)
      this.index--;
    else
      this.index = urlList.length - 1;
    notifyListeners();
    play(index: this.index);
  }
}
