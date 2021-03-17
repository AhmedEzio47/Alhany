import 'dart:async';

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
  List<String> urlList;
  final Function onComplete;
  final bool isLocal;

  bool playing;

  MyAudioPlayer(
      {this.url, this.urlList, this.isLocal = false, this.onComplete}) {
    initAudioPlayer();
  }

  int index = 0;

  initAudioPlayer() {
    advancedPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: advancedPlayer);
    currentIndexStream = _currentIndexStreamController.stream;
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

  StreamController<int> _currentIndexStreamController = StreamController<int>();
  Stream currentIndexStream;

  Future play({index}) async {
    print('audio url: $url');
    if (index == null) {
      index = this.index;
    }
    await advancedPlayer.play(url ?? urlList[index], isLocal: isLocal);
    playerState = AudioPlayerState.PLAYING;
    playing = true;
    notifyListeners();
  }

  Future stop() async {
    await advancedPlayer.stop();
    playerState = AudioPlayerState.STOPPED;
    position = null;
    duration = null;
    playing = false;
    notifyListeners();
    if (onComplete != null &&
        MelodyPage.recordingStatus == RecordingStatus.Recording) {
      onComplete();
    }
  }

  Future pause() async {
    await advancedPlayer.pause();
    playerState = AudioPlayerState.PAUSED;
    playing = false;
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
    _currentIndexStreamController.add(index);
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

  setAudioSource({List<String> urlList}) {
    this.urlList = urlList;
  }
}

/// Encapsulates the playback state and current position of the player.
class PlaybackEvent {
  /// The current processing state.
  final ProcessingState processingState;

  /// When the last time a position discontinuity happened, as measured in time
  /// since the epoch.
  final DateTime updateTime;

  /// The position at [updateTime].
  final Duration updatePosition;

  /// The buffer position.
  final Duration bufferedPosition;

  /// The media duration, or null if unknown.
  final Duration duration;

  /// The latest ICY metadata received through the audio stream.
  //final IcyMetadata icyMetadata;

  /// The index of the currently playing item.
  final int currentIndex;

  /// The current Android AudioSession ID.
  final int androidAudioSessionId;

  PlaybackEvent({
    this.processingState = ProcessingState.idle,
    DateTime updateTime,
    this.updatePosition = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration,
    //this.icyMetadata,
    this.currentIndex,
    this.androidAudioSessionId,
  }) : this.updateTime = updateTime ?? DateTime.now();

  PlaybackEvent copyWith({
    ProcessingState processingState,
    DateTime updateTime,
    Duration updatePosition,
    Duration bufferedPosition,
    double speed,
    Duration duration,
    //IcyMetadata icyMetadata,
    //UriAudioSource currentIndex,
    int androidAudioSessionId,
  }) =>
      PlaybackEvent(
        processingState: processingState ?? this.processingState,
        updateTime: updateTime ?? this.updateTime,
        updatePosition: updatePosition ?? this.updatePosition,
        bufferedPosition: bufferedPosition ?? this.bufferedPosition,
        duration: duration ?? this.duration,
        //icyMetadata: icyMetadata ?? this.icyMetadata,
        currentIndex: currentIndex ?? this.currentIndex,
        androidAudioSessionId:
            androidAudioSessionId ?? this.androidAudioSessionId,
      );

  @override
  String toString() =>
      "{processingState=$processingState, updateTime=$updateTime, updatePosition=$updatePosition}";
}

enum ProcessingState {
  /// The player has not loaded an [AudioSource].
  idle,

  /// The player is loading an [AudioSource].
  loading,

  /// The player is buffering audio and unable to play.
  buffering,

  /// The player is has enough audio buffered and is able to play.
  ready,

  /// The player has reached the end of the audio.
  completed,
}
