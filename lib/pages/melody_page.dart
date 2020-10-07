import 'dart:async';

import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/pages/get_ready_modal.dart';
import 'package:dubsmash/widgets/melody_player.dart';
import 'package:flutter/material.dart';

class MelodyPage extends StatefulWidget {
  final Melody melody;

  const MelodyPage({Key key, this.melody}) : super(key: key);

  @override
  _MelodyPageState createState() => _MelodyPageState();
}

class _MelodyPageState extends State<MelodyPage> {
  num _start = 5;
  String _getReadyText = 'Get Ready';
  Timer _timer;

  bool _getReady = false;

  MelodyPlayer _melodyPlayer;

  changeText() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            _getReadyText = 'GO';
            _start--;
          });
        } else if (_start < 0) {
          setState(() {
            _getReady = false;
            _start = 5;
            _getReadyText = 'Get Ready';
          });
          timer.cancel();
        } else {
          setState(() {
            _getReadyText = '$_start';
            _start--;
          });
        }
      },
    );
  }

  @override
  void initState() {
    _melodyPlayer = MelodyPlayer(
      url: widget.melody.audioUrl,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 150,
              ),
              Container(
                color: Colors.grey.shade200,
                width: 100,
                height: 100,
                child: Icon(
                  Icons.music_note,
                  color: MyColors.primaryColor,
                  size: 50,
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                widget.melody.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 30,
              ),
              _melodyPlayer,
              SizedBox(
                height: 70,
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _getReady = true;
                  });
                  changeText();
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: MyColors.primaryColor, shape: BoxShape.circle),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                ),
              )
            ],
          ),
          _getReady
              ? Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Container(
                        color: MyColors.lightPrimaryColor,
                        height: 200,
                        width: MediaQuery.of(context).size.width - 50,
                        child: Center(
                          child: Text(
                            _getReadyText,
                            style: TextStyle(fontSize: 34),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container()
        ],
      ),
    );
  }
}
