import 'package:Alhany/models/record.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;

class RecordFullscreen extends StatefulWidget {
  final Record record;
  final User singer;
  const RecordFullscreen({Key key, this.record, this.singer}) : super(key: key);
  @override
  _RecordFullscreenState createState() => _RecordFullscreenState();
}

class _RecordFullscreenState extends State<RecordFullscreen> with SingleTickerProviderStateMixin {
  bool abo = false;
  bool play = true;
  VideoPlayerController _controller;
  ScrollController _scrollController = ScrollController(initialScrollOffset: 0);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.record.audioUrl)
      ..initialize().then((value) {
        _controller.play();
        _controller.setLooping(false);
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.pause();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          fullscreen(),
        ],
      ),
    );
  }

  fullscreen() {
    return Stack(
      children: <Widget>[
        FlatButton(
            padding: EdgeInsets.all(0),
            onPressed: () {
              setState(() {
                if (play) {
                  _controller.pause();
                  play = !play;
                } else {
                  _controller.play();
                  play = !play;
                }
              });
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: VideoPlayer(_controller),
            )),
        Padding(
          padding: EdgeInsets.only(bottom: 70),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: MediaQuery.of(context).size.width - 100,
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10, bottom: 10),
                    child: Text(
                      '@spook_clothing',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 10),
                      child: Text.rich(
                        TextSpan(children: <TextSpan>[
                          TextSpan(text: 'Eiffel Tower'),
                          TextSpan(text: '#foot\n', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'Voir la traduction', style: TextStyle(fontSize: 12))
                        ]),
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      )),
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.music_note, size: 16, color: Colors.white),
                        Text('R10 - Oboy', style: TextStyle(color: Colors.white))
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Padding(
            padding: EdgeInsets.only(bottom: 65, right: 10),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 70,
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(bottom: 23),
                      width: 40,
                      height: 50,
                      child: Stack(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 19,
                              backgroundColor: Colors.black,
                              backgroundImage: NetworkImage(widget.singer?.profileImageUrl),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Color(0xfd2c58).withOpacity(1),
                              child: Center(child: Icon(Icons.add, size: 15, color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.thumb_up, size: 35, color: Colors.white),
                          Text('427.9K', style: TextStyle(color: Colors.white))
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: Icon(Icons.sms, size: 35, color: Colors.white)),
                          Text('2051', style: TextStyle(color: Colors.white))
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: Icon(Icons.share, size: 35, color: Colors.white)),
                          Text('Share', style: TextStyle(color: Colors.white))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ))
      ],
    );
  }

  buttonPlus() {
    return Container(
      width: 46,
      height: 30,
      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)), color: Colors.transparent),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 30,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)), color: Color(0x2dd3e7).withOpacity(1)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 28,
              height: 30,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)), color: Color(0xed316a).withOpacity(1)),
            ),
          ),
          Center(
            child: Container(
              width: 28,
              height: 30,
              decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)), color: Colors.white),
              child: Center(child: Icon(Icons.add, color: Colors.black)),
            ),
          )
        ],
      ),
    );
  }
}
