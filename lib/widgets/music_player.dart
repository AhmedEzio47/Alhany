import 'dart:async';
import 'package:intl/intl.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class MusicPlayer extends StatefulWidget {
  final String url;
  final Color backColor;
  Function onComplete;
  final bool isLocal;

  MusicPlayer({Key key, @required this.url, this.backColor, this.onComplete, this.isLocal = false}) : super(key: key);

  AudioPlayer advancedPlayer = AudioPlayer();
  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  Duration duration;
  Duration position;

  Future play() async {
    print('audio url: $url');

    await advancedPlayer.play(url);

    playerState = AudioPlayerState.PLAYING;
  }

  Future stop() async {
    await advancedPlayer.stop();
    playerState = AudioPlayerState.STOPPED;
    position = null;
    duration = null;
  }

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  _MusicPlayerState();

  AudioCache audioCache;

  get isPlaying => widget.playerState == AudioPlayerState.PLAYING;
  get isPaused => widget.playerState == AudioPlayerState.PAUSED;

  get durationText => widget.duration != null ? widget.duration.toString().split('.').first : '';

  get positionText => widget.position != null ? widget.position.toString().split('.').first : '';

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
            stop();
          }
        });
  }

  Future play() async {
    print('audio url: ${widget.url}');

    await widget.advancedPlayer.play(widget.url, isLocal: widget.isLocal);

    setState(() {
      widget.playerState = AudioPlayerState.PLAYING;
    });
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
        widget.position = null;
        widget.duration = null;
      });
    }

    if (widget.onComplete != null) {
      widget.onComplete();
    }
  }

  NumberFormat _numberFormatter = new NumberFormat("##");

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: widget.backColor,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  widget.position != null
                      ? Text(
                          '${_numberFormatter.format(widget.position.inMinutes)} : ${_numberFormatter.format(widget.position.inSeconds % 60)}',
                          style: TextStyle(color: Colors.white),
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
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 16.0),
                      ),
                      child: Slider(
                          activeColor: MyColors.darkPrimaryColor,
                          inactiveColor: Colors.grey.shade300,
                          value: widget.position?.inMilliseconds?.toDouble() ?? 0.0,
                          onChanged: (double value) {
                            widget.advancedPlayer.seek(Duration(seconds: value ~/ 1000));

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
                          style: TextStyle(color: Colors.white),
                        )
                      : Container(),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              !isPlaying
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            spreadRadius: 2,
                            blurRadius: 4,
                            offset: Offset(0, 2), // changes position of shadow
                          ),
                        ],
                      ),
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
                        color: Colors.grey.shade300,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            spreadRadius: 2,
                            blurRadius: 4,
                            offset: Offset(0, 2), // changes position of shadow
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: isPlaying ? () => pause() : null,
                        iconSize: 40.0,
                        icon: Icon(Icons.pause),
                        color: MyColors.primaryColor,
                      ),
                    ),
              SizedBox(
                height: 10,
              )
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }
}
