import 'dart:async';
import 'package:dubsmash/services/my_audio_player.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class MusicPlayer extends StatefulWidget {
  final String url;
  final Color backColor;
  final Function onComplete;
  final bool isLocal;
  final String title;

  MusicPlayer({Key key, @required this.url, this.backColor, this.onComplete, this.isLocal = false, this.title})
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

  void initAudioPlayer() {
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
          padding: const EdgeInsets.all(18.0),
          child: Container(
            color: widget.backColor,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  myAudioPlayer.position != null
                      ? Text(
                          '${_numberFormatter.format(myAudioPlayer.position.inMinutes)} : ${_numberFormatter.format(myAudioPlayer.position.inSeconds % 60)}',
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
                          '${_numberFormatter.format(_duration.inMinutes)} : ${_numberFormatter.format(_duration.inSeconds % 60)}',
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
              ),
              widget.title != null
                  ? Container(
                      width: MediaQuery.of(context).size.width - 150,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: MyColors.accentColor,
                          border: Border.all(color: MyColors.accentColor),
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      child: Text(
                        widget.title,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : Container(),
              SizedBox(height: 5)
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }
}
