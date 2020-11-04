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
  bool foryou = true;
  bool play = true;
  VideoPlayerController _controller;
  AnimationController animationController;
  PageController pageController = PageController(initialPage: 0, viewportFraction: 0.8);
  ScrollController _scrollController = ScrollController(initialScrollOffset: 0);
  PageController foryouController = new PageController();

  @override
  void initState() {
    super.initState();
    animationController = new AnimationController(vsync: this, duration: new Duration(seconds: 5));
    animationController.repeat();
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
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          homescreen(),
        ],
      ),
    );
  }

  homescreen() {
    if (foryou) {
      return PageView.builder(
          controller: foryouController,
          onPageChanged: (index) {
            setState(() {
              _controller.seekTo(Duration.zero);
              _controller.play();
            });
          },
          scrollDirection: Axis.vertical,
          itemCount: 5,
          itemBuilder: (context, index) {
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
          });
    } else {
      _controller.play();
      return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Créateurs tendances',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ))
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Center(
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          Center(
                            child: Text('Abonne-toi à un compte pour découvrir ses',
                                style: TextStyle(color: Colors.white.withOpacity(0.8))),
                          ),
                          Center(
                            child:
                                Text('dernières vidéos ici.', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Container(
                height: 372,
                margin: EdgeInsets.only(top: 25),
                child: PageView.builder(
                    dragStartBehavior: DragStartBehavior.down,
                    controller: pageController,
                    itemCount: 5,
                    itemBuilder: (context, position) {
                      return videoSlider(position);
                    }),
              )
            ],
          ));
    }
  }

  videoSlider(int index) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, widget) {
        double value = 1;
        if (pageController.position.haveDimensions) {
          value = pageController.page - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 372,
            width: Curves.easeInOut.transform(value) * 300,
            child: widget,
          ),
        );
      },
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: VideoPlayer(_controller),
          ),
          Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.close,
                  size: 15,
                  color: Colors.white,
                ),
              )),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: 15),
              height: 370 / 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: CircleAvatar(
                        backgroundColor: Colors.black,
                        backgroundImage: NetworkImage(widget.singer.profileImageUrl),
                        radius: 30,
                      )),
                  Padding(
                      padding: EdgeInsets.only(bottom: 6), child: Text('Spook', style: TextStyle(color: Colors.white))),
                  Text('@spook_clothing', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  Container(
                      height: 50,
                      margin: EdgeInsets.only(left: 50, right: 50, top: 12),
                      decoration: BoxDecoration(
                        color: Color(0xfe2b54).withOpacity(1),
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      child: Center(
                        child: Text(
                          'Abonnement',
                          style: TextStyle(color: Colors.white),
                        ),
                      ))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  buttonplus() {
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
