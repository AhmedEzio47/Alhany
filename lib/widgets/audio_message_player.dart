import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class AudioMessagePlayer extends StatefulWidget {
  final String? url;
  AudioMessagePlayer({Key? key, @required this.url}) : super(key: key);

  @override
  _AudioMessagePlayerState createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  _AudioMessagePlayerState();

  Duration? _duration;
  Duration? position;

  String? localFilePath;
  late MyAudioPlayer _myAudioPlayer;

  get durationText =>
      _duration != null ? _duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    _myAudioPlayer = MyAudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(0),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          !(_myAudioPlayer.isPlaying)
              ? IconButton(
                  onPressed: (_myAudioPlayer.isPlaying)
                      ? null
                      : () => _myAudioPlayer.play(),
                  iconSize: 24.0,
                  icon: Icon(Icons.play_arrow),
                  color: MyColors.accentColor,
                )
              : IconButton(
                  onPressed: (_myAudioPlayer.isPlaying)
                      ? () => _myAudioPlayer.pause()
                      : null,
                  iconSize: 24.0,
                  icon: Icon(Icons.pause),
                  color: MyColors.accentColor,
                ),
          _duration == null
              ? Container()
              : SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                  ),
                  child: Slider(
                      activeColor: MyColors.accentColor,
                      inactiveColor: Colors.grey.shade300,
                      value: position?.inSeconds?.toDouble() ?? 0.0,
                      onChanged: (double value) =>
                          _myAudioPlayer.seek(Duration(seconds: value ~/ 1000)),
                      min: 0.0,
                      max: _duration!.inSeconds.toDouble()),
                ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }
}
