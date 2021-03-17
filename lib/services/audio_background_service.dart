import 'dart:async';

import 'package:Alhany/services/my_audio_player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

class QueueState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;

  QueueState(this.queue, this.mediaItem);
}

class MediaState {
  final MediaItem mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

// class SeekBar extends StatefulWidget {
//   final Duration duration;
//   final Duration position;
//   final ValueChanged<Duration> onChanged;
//   final ValueChanged<Duration> onChangeEnd;
//
//   SeekBar({
//     @required this.duration,
//     @required this.position,
//     this.onChanged,
//     this.onChangeEnd,
//   });
//
//   @override
//   _SeekBarState createState() => _SeekBarState();
// }
//
// class _SeekBarState extends State<SeekBar> {
//   double _dragValue;
//   bool _dragging = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final value = min(_dragValue ?? widget.position?.inMilliseconds?.toDouble(),
//         widget.duration.inMilliseconds.toDouble());
//     if (_dragValue != null && !_dragging) {
//       _dragValue = null;
//     }
//     return Stack(
//       children: [
//         Slider(
//           min: 0.0,
//           max: widget.duration.inMilliseconds.toDouble(),
//           value: value,
//           onChanged: (value) {
//             if (!_dragging) {
//               _dragging = true;
//             }
//             setState(() {
//               _dragValue = value;
//             });
//             if (widget.onChanged != null) {
//               widget.onChanged(Duration(milliseconds: value.round()));
//             }
//           },
//           onChangeEnd: (value) {
//             if (widget.onChangeEnd != null) {
//               widget.onChangeEnd(Duration(milliseconds: value.round()));
//             }
//             _dragging = false;
//           },
//         ),
//         Positioned(
//           right: 16.0,
//           bottom: 0.0,
//           child: Text(
//               RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
//                       .firstMatch("$_remaining")
//                       ?.group(1) ??
//                   '$_remaining',
//               style: Theme.of(context).textTheme.caption),
//         ),
//       ],
//     );
//   }
//
//   Duration get _remaining => widget.duration - widget.position;
// }

/// This task defines logic for playing a list of podcast episodes.
class AudioPlayerTask extends BackgroundAudioTask {
  List<MediaItem> _mediaLibrary;

  List<MediaItem> mediaLibrary() {
    List<MediaItem> mediaLibrary = [];
    _player.urlList.forEach((element) {
      mediaLibrary.add(MediaItem(id: element, album: '', title: ''));
    });
    return mediaLibrary;
  }

  MyAudioPlayer _player = new MyAudioPlayer();
  AudioProcessingState _skipState;
  Seeker _seeker;
  StreamSubscription<PlaybackEvent> _eventSubscription;

  List<MediaItem> get queue => _mediaLibrary;
  int get index => _player.index;
  MediaItem get mediaItem => index == null ? null : queue[index];

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // We configure the audio session for speech since we're playing a podcast.
    // You can also put this in your app's initialisation if your app doesn't
    // switch between two types of audio as this example does.
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    // Broadcast media item changes.
    _player.currentIndexStream.listen((index) {
      if (index != null) AudioServiceBackground.setMediaItem(queue[index]);
    });

    // Load and broadcast the queue
    try {
      await _player.setAudioSource(
        urlList: queue.map((item) => item.id).toList(),
      );
      _mediaLibrary = mediaLibrary();
    } catch (e) {
      print("Error: $e");
      onStop();
    }
    AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    // Then default implementations of onSkipToNext and onSkipToPrevious will
    // delegate to this method.
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return;
    // During a skip, the player may enter the buffering state. We could just
    // propagate that state directly to AudioService clients but AudioService
    // has some more specific states we could use for skipping to next and
    // previous. This variable holds the preferred state to send instead of
    // buffering during a skip, and it is cleared as soon as the player exits
    // buffering (see the listener in onStart).
    _skipState = newIndex > index
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    // This jumps to the beginning of the queue item at newIndex.
    _player.seek(
      Duration.zero,
    );
    // Demonstrate custom events.
    AudioServiceBackground.sendCustomEvent('skip to $newIndex');
  }

  @override
  Future<void> onPlay() => _player.play();

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration position) => _player.seek(position);

  @override
  Future<void> onFastForward() => _seekRelative(fastForwardInterval);

  @override
  Future<void> onRewind() => _seekRelative(-rewindInterval);

  @override
  Future<void> onSeekForward(bool begin) async => _seekContinuously(begin, 1);

  @override
  Future<void> onSeekBackward(bool begin) async => _seekContinuously(begin, -1);

  @override
  Future<void> onStop() async {
    await _player.dispose();
    _eventSubscription.cancel();
    // It is important to wait for this state to be broadcast before we shut
    // down the task. If we don't, the background task will be destroyed before
    // the message gets sent to the UI.
    await _broadcastState();
    // Shut down this task
    await super.onStop();
  }

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _player.position + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
    // Perform the jump via a seek.
    await _player.seek(newPosition);
  }

  /// Begins or stops a continuous seek in [direction]. After it begins it will
  /// continue seeking forward or backward by 10 seconds within the audio, at
  /// intervals of 1 second in app time.
  void _seekContinuously(bool begin, int direction) {
    _seeker?.stop();
    if (begin) {
      _seeker = Seeker(_player, Duration(seconds: 10 * direction),
          Duration(seconds: 1), mediaItem)
        ..start();
    }
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      // bufferedPosition: _player.bufferedPosition,
      // speed: _player.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    // if (_skipState != null) return _skipState;
    // switch (_player.processingState) {
    //   case ProcessingState.idle:
    //     return AudioProcessingState.stopped;
    //   case ProcessingState.loading:
    //     return AudioProcessingState.connecting;
    //   case ProcessingState.buffering:
    //     return AudioProcessingState.buffering;
    //   case ProcessingState.ready:
    //     return AudioProcessingState.ready;
    //   case ProcessingState.completed:
    //     return AudioProcessingState.completed;
    //   default:
    //     throw Exception("Invalid state: ${_player.processingState}");
    // }
  }
}

/// An object that performs interruptable sleep.
class Sleeper {
  Completer _blockingCompleter;

  /// Sleep for a duration. If sleep is interrupted, a
  /// [SleeperInterruptedException] will be thrown.
  Future<void> sleep([Duration duration]) async {
    _blockingCompleter = Completer();
    if (duration != null) {
      await Future.any([Future.delayed(duration), _blockingCompleter.future]);
    } else {
      await _blockingCompleter.future;
    }
    final interrupted = _blockingCompleter.isCompleted;
    _blockingCompleter = null;
    if (interrupted) {
      throw SleeperInterruptedException();
    }
  }

  /// Interrupt any sleep that's underway.
  void interrupt() {
    if (_blockingCompleter?.isCompleted == false) {
      _blockingCompleter.complete();
    }
  }
}

class SleeperInterruptedException {}

class Seeker {
  final MyAudioPlayer player;
  final Duration positionInterval;
  final Duration stepInterval;
  final MediaItem mediaItem;
  bool _running = false;

  Seeker(
    this.player,
    this.positionInterval,
    this.stepInterval,
    this.mediaItem,
  );

  start() async {
    _running = true;
    while (_running) {
      Duration newPosition = player.position + positionInterval;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
      player.seek(newPosition);
      await Future.delayed(stepInterval);
    }
  }

  stop() {
    _running = false;
  }
}
