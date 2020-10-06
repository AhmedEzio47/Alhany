import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class MelodyPlayer extends StatefulWidget {
  final String url;
  MelodyPlayer({Key key, @required this.url}) : super(key: key);

  //static _MelodyPlayerState of(BuildContext context) => context.findAncestorStateOfType();

//  static _MelodyPlayerState of(BuildContext context, {bool root = false}) => root
//      ? context.findRootAncestorStateOfType<_MelodyPlayerState>()
//      : context.findAncestorStateOfType<_MelodyPlayerState>();


  @override
  _MelodyPlayerState createState() => _MelodyPlayerState();
}

class _MelodyPlayerState extends State<MelodyPlayer> {
  bool _loading = false;

  _MelodyPlayerState();

  Duration _duration;
  Duration _position;

  AudioPlayer advancedPlayer = AudioPlayer();
  AudioCache audioCache;

  String localFilePath;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  get isPlaying => playerState == AudioPlayerState.PLAYING;
  get isPaused => playerState == AudioPlayerState.PAUSED;

  get durationText =>
      _duration != null ? _duration.toString().split('.').first : '';

  get positionText =>
      _position != null ? _position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();

    initAudioPlayer();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void initAudioPlayer() {
    advancedPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: advancedPlayer);
    advancedPlayer.durationHandler = (d) => setState(() {
          _duration = d;
        });

    advancedPlayer.positionHandler = (p) => setState(() {
          _position = p;
          print('d:${_duration.inMilliseconds} - p:${p.inMilliseconds}');
          if (_duration.inMilliseconds - p.inMilliseconds < 200) {
            setState(() {
              playerState = AudioPlayerState.STOPPED;
              _duration = null;
            });
          }
        });
  }

  Future play() async {
    print('audio url: ${widget.url}');
    setState(() {
      _loading = true;
    });
    await advancedPlayer.play(widget.url);
    setState(() {
      _loading = false;
    });
    setState(() {
      playerState = AudioPlayerState.PLAYING;
    });
  }

  Future _playLocal() async {
    await advancedPlayer.play(localFilePath, isLocal: true);
    setState(() => playerState = AudioPlayerState.PLAYING);
  }

  Future pause() async {
    await advancedPlayer.pause();
    setState(() => playerState = AudioPlayerState.PAUSED);
  }

  Future stop() async {
    await advancedPlayer.stop();

    if (mounted) {
      setState(() {
        playerState = AudioPlayerState.STOPPED;
        _position = _duration;
      });
    }

    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
  }

  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
    Uint8List bytes;
    try {
      bytes = await readBytes(url);
    } on ClientException {
      rethrow;
    }
    return bytes;
  }

  Future _loadFile() async {
    final bytes = await _loadFileBytes(widget.url,
        onError: (Exception exception) =>
            print('_loadFile => exception $exception'));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/audio.mp3');

    await file.writeAsBytes(bytes);
    if (await file.exists())
      setState(() {
        localFilePath = file.path;
      });
  }

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: Colors.white,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _loading
                  ? Loading(indicator: BallPulseIndicator(), size: 25.0)
                  : !isPlaying
                      ? IconButton(
                          onPressed: isPlaying ? null : () => play(),
                          iconSize: 24.0,
                          icon: Icon(Icons.play_arrow),
                          color: MyColors.primaryColor,
                        )
                      : IconButton(
                          onPressed: isPlaying ? () => pause() : null,
                          iconSize: 24.0,
                          icon: Icon(Icons.pause),
                          color: MyColors.primaryColor,
                        ),
              Expanded(
                flex: 9,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                  ),
                  child: Slider(
                      activeColor: MyColors.primaryColor,
                      inactiveColor: Colors.grey.shade400,
                      value: _position?.inMilliseconds?.toDouble() ?? 0.0,
                      onChanged: (double value) {
                        advancedPlayer.seek(Duration(seconds: value ~/ 1000));

                        if (!isPlaying) {
                          play();
                        }
                      },
                      min: 0.0,
                      max: _duration != null
                          ? _duration?.inMilliseconds?.toDouble()
                          : 1.7976931348623157e+308),
                ),
              ),
            ]),
          ),
        ),
      );

  Row _buildProgressView() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: EdgeInsets.all(0),
        child: CircularProgressIndicator(
          value: _position != null && _position.inMilliseconds > 0
              ? (_position?.inMilliseconds?.toDouble() ?? 0.0) /
                  (_duration?.inMilliseconds?.toDouble() ?? 0.0)
              : 0.0,
          valueColor: AlwaysStoppedAnimation(Colors.cyan),
          backgroundColor: Colors.grey.shade400,
        ),
      ),
      Text(
        _position != null
            ? "${positionText ?? ''} / ${durationText ?? ''}"
            : _duration != null ? durationText : '',
        style: TextStyle(fontSize: 16.0),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }
}
