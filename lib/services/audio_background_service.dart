import 'dart:async';

import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:Alhany/widgets/audio_message_player.dart';
import 'package:audio_service/audio_service.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  MyAudioPlayer _audioPlayer = MyAudioPlayer();
  AudioProcessingState _audioProcessingState;
  bool _playing;
  List<Melody> _queue;
  int _queueIndex = -1;
  bool get hasNext => _queueIndex + 1 < _queue.length;
  bool get hasPrevious => _queue.length > 0;
  Melody get mediaItem => _queue[_queueIndex];

  StreamSubscription<PlayerState> _playerStateSubscription;

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    super.onStart(params);
    List<MediaItem> queue;
    for (Melody item in _queue) {
      queue.add(MediaItem(id: item.id, album: item.singer, title: item.name));
    }
    AudioServiceBackground.setQueue(queue);
    //_playerStateSubscription = _myAudioPlayer.p
  }

  @override
  Future<void> onPlay() async {
    super.onPlay();
    if (_audioProcessingState == null) {
      _playing = true;
      _audioPlayer.play();
    }
  }

  @override
  Future<void> onPause() async {
    super.onPause();
    _playing = false;
    _audioPlayer.pause();
  }

  @override
  Future<void> onSkipToNext() async {
    skip(1);
  }

  void skip(int offset) async {
    int newPos = _queueIndex + offset;
    _queueIndex = newPos;
    _audioProcessingState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    AudioServiceBackground.setMediaItem(MediaItem(
        id: mediaItem.id, album: mediaItem.singer, title: mediaItem.name));
    if (offset == 1) {
      _audioPlayer.next();
    } else if (offset == -1) {
      _audioPlayer.prev();
    }
    _audioProcessingState = null;
    if (_playing) {
      onPlay();
    } else {
      //
      _setState(
        processingState: AudioProcessingState.ready,
      );
    }
  }

  @override
  Future<void> onSkipToPrevious() async {
    skip(-1);
  }

  @override
  Future<void> onStop() async {
    _playing = false;
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
    return await super.onStop();
  }

  @override
  Future<void> onSeekTo(Duration position) async {
    _audioPlayer.seek(position);
  }

  @override
  Future<void> onClick(MediaButton button) async {
    super.onClick(button);
  }

  Future<void> _setState(
      {AudioProcessingState processingState,
      Duration position,
      Duration bufferedPosition}) async {
    if (position == null) {
      position = _audioPlayer.position;
    }
    await AudioServiceBackground.setState(
        controls: getControls(),
        processingState:
            processingState ?? AudioServiceBackground.state.processingState,
        playing: _playing,
        position: position,
        systemActions: [MediaAction.seekTo]);
  }

  MediaControl playControl = MediaControl(
      androidIcon: 'drawable/play', label: 'Play', action: MediaAction.play);
  MediaControl pauseControl = MediaControl(
      androidIcon: 'drawable/pause', label: 'Pause', action: MediaAction.pause);
  MediaControl stopControl = MediaControl(
      androidIcon: 'drawable/stop', label: 'Stop', action: MediaAction.stop);
  MediaControl nextControl = MediaControl(
      androidIcon: 'drawable/next',
      label: 'Next',
      action: MediaAction.skipToNext);
  MediaControl prevControl = MediaControl(
      androidIcon: 'drawable/previous',
      label: 'Previous',
      action: MediaAction.skipToPrevious);

  List<MediaControl> getControls() {
    if (_playing) {
      return [prevControl, pauseControl, nextControl];
    } else {
      return [prevControl, playControl, nextControl];
    }
  }
}
