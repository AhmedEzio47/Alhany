import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/services/audio_recorder.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:audio_manager/audio_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

class MyAudioPlayer with ChangeNotifier {
  // AudioPlayer advancedPlayer = AudioPlayer();
  // AudioCache audioCache;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  Duration get duration => AudioManager.instance.duration;
  Duration get position => AudioManager.instance.position;

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
    // advancedPlayer.durationHandler = (d) {
    //   duration = d;
    //   notifyListeners();
    //   // print('my duration:$duration');
    // };

    // advancedPlayer.positionHandler = (p) {
    //   position = p;
    //   print('P:${p.inMilliseconds}');
    //   print('D:${duration.inMilliseconds}');
    //   notifyListeners();
    //
    //   if (duration.inMilliseconds - p.inMilliseconds <
    //       Constants.endPositionOffsetInMilliSeconds) {
    //     stop();
    //     if (urlList != null) {
    //       if (this.index < urlList.length - 1)
    //         this.index++;
    //       else
    //         this.index = 0;
    //       play(index: this.index);
    //       notifyListeners();
    //     } else {
    //       stop();
    //     }
    //   } else if (duration.inMilliseconds - p.inMilliseconds == 0) {
    //     if (urlList != null) {
    //       if (this.index < urlList.length - 1)
    //         this.index++;
    //       else
    //         this.index = 0;
    //       play(index: this.index);
    //       notifyListeners();
    //     } else {
    //       stop();
    //     }
    //   }
    // };
    AudioManager.instance.onEvents((events, args) {
      switch (events) {
        case AudioManagerEvents.playstatus:
          if (playerState == PlayerState.playing) {
            pause();
          } else {
            play();
          }
          break;
        case AudioManagerEvents.stop:
          if (playerState == PlayerState.playing) stop();
          break;
        default:
          break;
      }
    });
    AudioManager.instance
        .start(
            url,
            // "network format resource"
            // "local resource (file://${file.path})"
            'Salma',
            desc: 'is my love',
            // cover: "network cover image resource"
            cover: '')
        .then((err) {
      print(err);
    });
  }

  Future play({index}) async {
    print('audio url: $url');
    if (index == null) {
      index = this.index;
    }
    AudioManager.instance.playOrPause();
    playerState = AudioPlayerState.PLAYING;
    notifyListeners();
  }

  Future stop() async {
    AudioManager.instance.stop();

    playerState = AudioPlayerState.STOPPED;
    // position = null;
    // duration = null;
    notifyListeners();
    if (onComplete != null &&
        MelodyPage.recordingStatus == RecordingStatus.Recording) {
      onComplete();
    }
  }

  Future pause() async {
    AudioManager.instance.playOrPause();

    playerState = AudioPlayerState.PAUSED;
    notifyListeners();
  }

  seek(Duration p) {
    AudioManager.instance.seekTo(p);

    notifyListeners();
  }

  next() {
    if (this.index < urlList.length - 1)
      this.index++;
    else
      this.index = 0;
    notifyListeners();
    play(index: this.index);
  }

  prev() {
    if (this.index > 0)
      this.index--;
    else
      this.index = urlList.length - 1;
    notifyListeners();
    play(index: this.index);
  }
}
