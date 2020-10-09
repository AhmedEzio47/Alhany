import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:path_provider/path_provider.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class MelodyPlayer extends StatefulWidget {
  final String url;
  MelodyPlayer({Key key, @required this.url}) : super(key: key);

  AudioPlayer advancedPlayer = AudioPlayer();
  AudioPlayerState playerState = AudioPlayerState.STOPPED;
  bool loading = false;

  Duration duration;
  Duration position;

  Future play() async {
    print('audio url: $url');

    loading = true;

    await advancedPlayer.play(url);

    loading = false;

    playerState = AudioPlayerState.PLAYING;
  }

  Future stop() async {
    await advancedPlayer.stop();

    playerState = AudioPlayerState.STOPPED;
    position = duration;
  }

  @override
  _MelodyPlayerState createState() => _MelodyPlayerState();
}

class _MelodyPlayerState extends State<MelodyPlayer> {
  _MelodyPlayerState();

  AudioCache audioCache;

  String localFilePath;

  get isPlaying => widget.playerState == AudioPlayerState.PLAYING;
  get isPaused => widget.playerState == AudioPlayerState.PAUSED;

  get durationText => widget.duration != null
      ? widget.duration.toString().split('.').first
      : '';

  get positionText => widget.position != null
      ? widget.position.toString().split('.').first
      : '';

  bool isMuted = false;

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
    widget.advancedPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: widget.advancedPlayer);
    widget.advancedPlayer.durationHandler = (d) => setState(() {
          widget.duration = d;
        });

    widget.advancedPlayer.positionHandler = (p) => setState(() {
          widget.position = p;
          print('d:${widget.duration.inMilliseconds} - p:${p.inMilliseconds}');
          if (widget.duration.inMilliseconds - p.inMilliseconds < 200) {
            setState(() {
              widget.playerState = AudioPlayerState.STOPPED;
              widget.duration = null;
            });
          }
        });
  }

  Future play() async {
    print('audio url: ${widget.url}');
    setState(() {
      widget.loading = true;
    });
    await widget.advancedPlayer.play(widget.url);
    setState(() {
      widget.loading = false;
    });
    setState(() {
      widget.playerState = AudioPlayerState.PLAYING;
    });
  }

  Future _playLocal() async {
    await widget.advancedPlayer.play(localFilePath, isLocal: true);
    setState(() => widget.playerState = AudioPlayerState.PLAYING);
  }

  Future pause() async {
    await widget.advancedPlayer.pause();
    setState(() => widget.playerState = AudioPlayerState.PAUSED);
  }

  Future stop() async {
    await widget.advancedPlayer.stop();
    if (mounted) {
      setState(() {
        widget.playerState = AudioPlayerState.STOPPED;
        widget.position = widget.duration;
      });
    }
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

  NumberFormat _numberFormatter = new NumberFormat("##");

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: Colors.white,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  widget.position != null
                      ? Text(
                          '${_numberFormatter.format(widget.position.inMinutes)} : ${_numberFormatter.format(widget.position.inSeconds % 60)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        )
                      : Container(),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 9,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5.0,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 8.0),
                        overlayShape:
                            RoundSliderOverlayShape(overlayRadius: 16.0),
                      ),
                      child: Slider(
                          activeColor: MyColors.primaryColor,
                          inactiveColor: Colors.grey.shade400,
                          value: widget.position?.inMilliseconds?.toDouble() ??
                              0.0,
                          onChanged: (double value) {
                            widget.advancedPlayer
                                .seek(Duration(seconds: value ~/ 1000));

                            if (!isPlaying) {
                              play();
                            }
                          },
                          min: 0.0,
                          max: widget.duration != null
                              ? widget.duration?.inMilliseconds?.toDouble()
                              : 1.7976931348623157e+308),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  widget.duration != null
                      ? Text(
                          '${_numberFormatter.format(widget.duration.inMinutes)} : ${_numberFormatter.format(widget.duration.inSeconds % 60)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        )
                      : Container(),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
              widget.loading
                  ? Loading(indicator: BallPulseIndicator(), size: 25.0)
                  : !isPlaying
                      ? Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade400),
                          child: IconButton(
                            onPressed: isPlaying ? null : () => play(),
                            iconSize: 40.0,
                            icon: Icon(Icons.play_arrow),
                            color: MyColors.primaryColor,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade400),
                          child: IconButton(
                            onPressed: isPlaying ? () => pause() : null,
                            iconSize: 40.0,
                            icon: Icon(Icons.pause),
                            color: MyColors.primaryColor,
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
          value: widget.position != null && widget.position.inMilliseconds > 0
              ? (widget.position?.inMilliseconds?.toDouble() ?? 0.0) /
                  (widget.duration?.inMilliseconds?.toDouble() ?? 0.0)
              : 0.0,
          valueColor: AlwaysStoppedAnimation(Colors.cyan),
          backgroundColor: Colors.grey.shade400,
        ),
      ),
      Text(
        widget.position != null
            ? "${positionText ?? ''} / ${durationText ?? ''}"
            : widget.duration != null ? durationText : '',
        style: TextStyle(fontSize: 16.0),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }
}
