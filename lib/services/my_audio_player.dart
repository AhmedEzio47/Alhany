//import 'package:Alhany/services/audio_background_service.dart';
//import 'package:audio_service/audio_service.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/services/audio_recorder.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:sounds/sounds.dart';
//import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';

// NOTE: Your entrypoint MUST be a top-level function.
// void _audioPlayerTaskEntrypoint() async {
//   AudioServiceBackground.run(() => AudioPlayerTask(mediaLibrary: mediaLibrary));
// }

//List<MediaItem> mediaLibrary = [];

class MyAudioPlayer with ChangeNotifier {
  AudioPlayer advancedPlayer = AudioPlayer();
  SoundPlayer soundPlayer;
  Track _track;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;
  Duration duration;
  Duration position;
  Stream<PlaybackDisposition> disposition;

  final String url;
  final List<String> urlList;
  final Function onComplete;
  final bool isLocal;

  MyAudioPlayer(
      {this.url, this.urlList, this.isLocal = false, this.onComplete}) {
    //initAudioPlayer();
    initSoundPlayer();
  }

  int index = 0;
  Function onPlayingStarted;
  bool _onPlayingStartedCalled = false;

  initAudioPlayer() {
    advancedPlayer = AudioPlayer();

    // if (this.url != null) {
    //   mediaLibrary = [
    //     MediaItem(
    //       album: "Science Friday",
    //       title: "A Salute To Head-Scratching Science",
    //       artist: "Science Friday and WNYC Studios",
    //       artUri: "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
    //       id: url,
    //       duration: duration,
    //     )
    //   ];
    // }
    // AudioService.start(
    //   backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
    //   androidNotificationChannelName: 'Audio Service Demo',
    //   // Enable this if you want the Android service to exit the foreground state on pause.
    //   //androidStopForegroundOnPause: true,
    //   androidNotificationColor: 0xFF2196f3,
    //   androidNotificationIcon: 'mipmap/ic_launcher',
    //   androidEnableQueue: true,
    // );
    advancedPlayer.durationHandler = (d) {
      duration = d;
      notifyListeners();
      // print('my duration:$duration');
    };

    advancedPlayer.positionHandler = (p) {
      if (p.inMicroseconds > 0 &&
          onPlayingStarted != null &&
          !_onPlayingStartedCalled) {
        _onPlayingStartedCalled = true;
        onPlayingStarted();
      }
      position = p;
      print('P:${p.inMilliseconds}');
      //print('D:${duration.inMilliseconds}');
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

  initSoundPlayer() {
    soundPlayer = SoundPlayer.noUI();
    disposition = soundPlayer.dispositionStream();
  }

  Future play({index, Function onPlayingStarted}) async {
    if (soundPlayer.isPaused) soundPlayer.resume();

    if (isLocal) {
      _track = Track.fromFile(url ?? urlList[index]);
    } else {
      _track = Track.fromURL(url ?? urlList[index]);
    }
    soundPlayer.play(_track);
    //await advancedPlayer.play(url ?? urlList[index], isLocal: isLocal);

    this.onPlayingStarted = onPlayingStarted;
    print('audio url: $url');
    if (index == null) {
      index = this.index;
    }
    playerState = AudioPlayerState.PLAYING;
    notifyListeners();
  }

  Future stop() async {
    //await advancedPlayer.stop();
    await soundPlayer.stop();
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
    //await advancedPlayer.pause();
    await soundPlayer.pause();

    playerState = AudioPlayerState.PAUSED;
    notifyListeners();
  }

  seek(Duration p) {
    //advancedPlayer.seek(p);
    soundPlayer.seekTo(p);
    notifyListeners();
  }

  next() {
    //advancedPlayer.stop();
    soundPlayer.stop();

    if (this.index < urlList.length - 1)
      this.index++;
    else
      this.index = 0;
    notifyListeners();
    play(index: this.index);
  }

  prev() {
    //advancedPlayer.stop();
    soundPlayer.stop();

    if (this.index > 0)
      this.index--;
    else
      this.index = urlList.length - 1;
    notifyListeners();
    play(index: this.index);
  }
}
