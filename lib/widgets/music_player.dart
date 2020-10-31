import 'dart:async';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }
enum PlayBtnPosition { bottom, left }

class MusicPlayer extends StatefulWidget {
  final String url;
  final Color backColor;
  final Function onComplete;
  final bool isLocal;
  final String title;
  final bool recordBtnVisible;
  final double btnSize;
  final int initialDuration;
  final PlayBtnPosition playBtnPosition;
  final bool isCompact;

  final Melody melody;

  MusicPlayer(
      {Key key,
      @required this.url,
      this.backColor,
      this.onComplete,
      this.isLocal = false,
      this.title,
      this.recordBtnVisible = false,
      this.btnSize = 40.0,
      this.initialDuration,
      this.melody,
      this.playBtnPosition = PlayBtnPosition.bottom,
      this.isCompact = false})
      : super(key: key);

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  _MusicPlayerState();

  MyAudioPlayer myAudioPlayer;

  get isPlaying => myAudioPlayer.playerState == AudioPlayerState.PLAYING;
  get isPaused => myAudioPlayer.playerState == AudioPlayerState.PAUSED;

  get durationText => myAudioPlayer.duration != null ? myAudioPlayer.duration.toString().split('.').first : '';

  get positionText => myAudioPlayer.position != null ? myAudioPlayer.position.toString().split('.').first : '';

  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  @override
  void dispose() {
    myAudioPlayer.stop();
    super.dispose();
  }

  Duration _duration;

  void initAudioPlayer() async {
    myAudioPlayer = MyAudioPlayer(url: widget.url, isLocal: widget.isLocal, onComplete: widget.onComplete);
    myAudioPlayer.addListener(() {
      if (mounted) {
        setState(() {
          _duration = myAudioPlayer.duration;
        });
      }
    });
  }

  Future play() async {
    print('audio url: ${widget.url}');
    myAudioPlayer.play();
  }

  Future pause() async {
    await myAudioPlayer.pause();
  }

  Future stop() async {
    await myAudioPlayer.stop();
  }

  NumberFormat _numberFormatter = new NumberFormat("##");

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(0),
        child: Padding(
          padding: EdgeInsets.all(widget.isCompact ? 8 : 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: new BorderRadius.circular(20.0),
              color: widget.backColor,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              widget.isCompact
                  ? Container()
                  : SizedBox(
                      height: 5,
                    ),
              widget.title != null
                  ? Text(
                      widget.title,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  : Container(),
              Row(
                children: [
                  widget.isCompact
                      ? Container()
                      : SizedBox(
                          height: 10,
                        ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: widget.playBtnPosition == PlayBtnPosition.left ? playPauseBtn() : Container(),
                  ),
                  myAudioPlayer.position != null
                      ? Text(
                          '${_numberFormatter.format(myAudioPlayer.position.inMinutes)}:${_numberFormatter.format(myAudioPlayer.position.inSeconds % 60)}',
                          style: TextStyle(color: Colors.white),
                        )
                      : Text(
                          '0:0',
                          style: TextStyle(color: Colors.white),
                        ),
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
                            value: myAudioPlayer.position?.inMilliseconds?.toDouble() ?? 0.0,
                            onChanged: (double value) {
                              myAudioPlayer.seek(Duration(seconds: _duration.inMilliseconds ~/ 1000));

                              if (!isPlaying) {
                                play();
                              }
                            },
                            min: 0.0,
                            max: _duration != null ? _duration?.inMilliseconds?.toDouble() : 1.7976931348623157e+308)),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  myAudioPlayer.duration != null
                      ? Text(
                          '${_numberFormatter.format(_duration.inMinutes)}:${_numberFormatter.format(_duration.inSeconds % 60)}',
                          style: TextStyle(color: Colors.white),
                        )
                      : Text(
                          '${_numberFormatter.format(widget.initialDuration ~/ 60)}:${_numberFormatter.format(widget.initialDuration % 60)}',
                          style: TextStyle(color: Colors.white),
                        ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
              widget.isCompact
                  ? Container()
                  : SizedBox(
                      height: 10,
                    ),
              widget.playBtnPosition == PlayBtnPosition.bottom
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        playPauseBtn(),
                        SizedBox(
                          width: 20,
                        ),
                        widget.recordBtnVisible
                            ? InkWell(
                                onTap: () => Navigator.of(context)
                                    .pushNamed('/melody-page', arguments: {'melody': widget.melody}),
                                child: Container(
                                  height: widget.btnSize,
                                  width: widget.btnSize,
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
                                  child: Icon(
                                    Icons.mic,
                                    color: MyColors.primaryColor,
                                  ),
                                ),
                              )
                            : Container()
                      ],
                    )
                  : Container(),
              widget.playBtnPosition == PlayBtnPosition.bottom ? SizedBox(height: 10) : Container()
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }

  Widget playPauseBtn() {
    return !isPlaying
        ? InkWell(
            onTap: () => isPlaying ? null : play(),
            child: Container(
              height: widget.btnSize,
              width: widget.btnSize,
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
              child: Icon(
                Icons.play_arrow,
                size: widget.btnSize - 5,
                color: MyColors.primaryColor,
              ),
            ),
          )
        : InkWell(
            onTap: isPlaying ? () => pause() : null,
            child: Container(
              height: widget.btnSize,
              width: widget.btnSize,
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
              child: Icon(
                Icons.pause,
                color: MyColors.primaryColor,
                size: widget.btnSize - 5,
              ),
            ),
          );
  }
}
