import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:audio_session/audio_session.dart';
//import 'package:audioplayers/audio_cache.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';

import 'new_recorder.dart';

class MyAudioPlayer with ChangeNotifier {
  AudioPlayer _player = AudioPlayer();
  //AudioCache audioCache;

  get isPlaying => _player.playing;

  Duration duration;
  Duration position;
  final List<String> urlList;
  final Function onComplete;
  final Function onPlayingStarted;
  final bool isLocal;

  MyAudioPlayer(
      {this.urlList,
      this.isLocal = false,
      this.onComplete,
      this.onPlayingStarted}) {
    initAudioPlayer();
  }

  int index = 0;

  bool onPlayingStartedCalled = false;

  initAudioPlayer() async {
    //advancedPlayer = AudioPlayer();
    //audioCache = AudioCache(fixedPlayer: advancedPlayer);

    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
          print('A stream error occurred: $e');
        });
    // Try to load audio from a source and catch any errors.
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(
          urlList[index])));
    } catch (e) {
      print("Error loading audio source: $e");
    }
    if (isLocal)
      duration = await _player.setFilePath(urlList[index]);
    else
      duration = await _player.setUrl(urlList[index]);

    _player.positionStream.listen((p) {
      if (onPlayingStarted != null) {
        if (p > Duration(microseconds: 1) && !onPlayingStartedCalled) {
          onPlayingStarted();
          onPlayingStartedCalled = true;
        }
      }
      position = p;
      print('P:${p.inMilliseconds}');
      print('D:${duration.inMilliseconds}');
      notifyListeners();

      if (duration.inMilliseconds - p.inMilliseconds <
          Constants.endPositionOffsetInMilliSeconds) {
        stop();
        if (urlList.length > 1) {
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
        if (urlList.length > 1) {
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
    });
  }

  Future play({index = 0}) async {
    if (index == null) {
      index = this.index;
    }
    if (isLocal)
      duration = await _player.setFilePath(urlList[index]);
    else
      duration = await _player.setUrl(urlList[index]);
    await _player.play();

    notifyListeners();
  }

  Future stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    // position = null;
    // duration = null;
    notifyListeners();
    if (onComplete != null &&
        MelodyPage.recordingStatus == RecordingStatus.Recording) {
      onComplete();
    }
  }

  Future pause() async {
    await _player.pause();
    notifyListeners();
  }

  seek(Duration p) {
    _player.seek(p);
    notifyListeners();
  }

  next() {
    _player.stop();
    if (this.index < urlList.length - 1)
      this.index++;
    else
      this.index = 0;
    notifyListeners();
    play(index: this.index);
  }

  prev() {
    _player.stop();
    if (this.index > 0)
      this.index--;
    else
      this.index = urlList.length - 1;
    notifyListeners();
    play(index: this.index);
  }
}
