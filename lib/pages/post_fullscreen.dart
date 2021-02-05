import 'dart:math' as math;

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:video_player/video_player.dart';

class PostFullscreen extends StatefulWidget {
  final Record record;
  final News news;
  final User singer;
  final Melody melody;
  const PostFullscreen(
      {Key key, this.record, this.singer, this.melody, this.news})
      : super(key: key);
  @override
  _PostFullscreenState createState() => _PostFullscreenState();
}

class _PostFullscreenState extends State<PostFullscreen> {
  bool isLiked = false;
  bool isLikeEnabled = true;
  var likes = [];

  bool play = true;
  VideoPlayerController _controller;

  bool _isFollowing = false;

  bool _scrollable = true;

  isFollowing() async {
    if (Constants.currentUserID == _singer?.id) return true;

    DocumentSnapshot snapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('following')
        .doc(_singer?.id)
        .get();
    return snapshot.exists;
  }

  User _singer;
  getSinger() async {
    User singer = await DatabaseService.getUserWithId(_record.singerId);
    setState(() {
      _singer = singer;
    });
  }

  void initLikes({Record record, News news}) async {
    CollectionReference collectionReference;
    if (record != null) {
      collectionReference = recordsRef;
    } else if (news != null) {
      collectionReference = newsRef;
    }
    DocumentSnapshot likedSnapshot = await collectionReference
        .doc(record?.id ?? news?.id)
        .collection('likes')
        ?.doc(Constants.currentUserID)
        ?.get();

    //Solves the problem setState() called after dispose()
    if (mounted) {
      setState(() {
        isLiked = likedSnapshot.exists;
      });
    }
  }

  Future<void> likeBtnHandler({Record record, News news}) async {
    setState(() {
      isLikeEnabled = false;
    });
    CollectionReference collectionReference;
    if (record != null) {
      collectionReference = recordsRef;
    } else if (news != null) {
      collectionReference = newsRef;
    }
    if (isLiked == true) {
      await collectionReference
          .doc(record?.id ?? news?.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();

      await collectionReference
          .doc(record?.id ?? news?.id)
          .update({'likes': FieldValue.increment(-1)});

      await NotificationHandler.removeNotification(
          record?.singerId ?? Constants.startUser.id,
          record?.id ?? news?.id,
          'like');
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isLiked == false) {
      await collectionReference
          .doc(record?.id ?? news?.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await collectionReference
          .doc(record?.id ?? news?.id)
          .update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
      });

      await NotificationHandler.sendNotification(
          record?.singerId ?? Constants.startUser.id,
          'New Post Like',
          Constants.currentUser.name + ' likes your post',
          record?.id ?? news?.id,
          record != null ? 'record_like' : 'news_like');
    }
    var recordMeta = await DatabaseService.getPostMeta(
        recordId: record?.id, newsId: news?.id);
    setState(() {
      record?.likes = recordMeta['likes'];
      news?.likes = recordMeta['likes'];
      isLikeEnabled = true;
    });
  }

  void _goToProfilePage() {
    Navigator.of(context).pushNamed('/profile-page', arguments: {
      'user_id': widget.record?.singerId ?? Constants.startUser.id
    });
  }

  void _goToMelodyPage() {
    Navigator.of(context)
        .pushNamed('/melody-page', arguments: {'melody': widget.melody});
  }

  Record _record;
  ScrollDirection _scrollDirection = ScrollDirection.reverse;
  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      print(_pageController.position.userScrollDirection.toString());
      if (_pageController.position.userScrollDirection != _scrollDirection) {
        print('direction changed');
        setState(() {
          _scrollable = true;
        });
      }
      if (_pageController.position.userScrollDirection ==
          ScrollDirection.forward) {
        print('swiped down');
      } else {
        print('swiped up');
      }

      _scrollDirection = _pageController.position.userScrollDirection;
    });
    _next = widget.record;
    _previous = widget.record;
    if (widget.record != null) {
      setState(() {
        _record = widget.record;
      });
      DatabaseService.incrementRecordViews(_record.id);
    } else if (widget.news != null) {
      DatabaseService.incrementNewsViews(widget.news.id);
    }
    initVideoPlayer(_record?.url ?? widget.news?.contentUrl);
    setState(() {
      _singer = widget.singer;
    });
    isFollowing();
    initLikes(record: _record, news: widget.news);
  }

  initVideoPlayer(String url) {
    if (_controller != null) {
      _controller.dispose();
      setState(() {
        _controller = null;
      });
    }
    _controller = VideoPlayerController.network(url)
      ..initialize().then((value) {
        _controller.play();
        _controller.setLooping(false);
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.pause();
    _controller.dispose();
  }

  Record _next, _previous;
  DragStartDetails startVerticalDragDetails;
  DragUpdateDetails updateVerticalDragDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          widget.record != null
              ? SimpleGestureDetector(
                  onVerticalSwipe: (SwipeDirection swipeDirection) {
                    if (swipeDirection == SwipeDirection.up &&
                        _scrollDirection == ScrollDirection.forward) {
                      setState(() {
                        _scrollable = true;
                      });
                      _pageController.animateToPage(_page + 1,
                          duration: Duration(milliseconds: 800),
                          curve: Curves.easeOut);
                      print('Swipe up');
                    } else if (swipeDirection == SwipeDirection.down &&
                        _scrollDirection == ScrollDirection.reverse) {
                      setState(() {
                        _scrollable = true;
                      });
                      _pageController.animateToPage(_page - 1,
                          duration: Duration(milliseconds: 800),
                          curve: Curves.easeOut);
                      print('Swipe down');
                    }
                  },
                  child: PageView.builder(
                      controller: _pageController,
                      physics:
                          !_scrollable ? NeverScrollableScrollPhysics() : null,
                      onPageChanged: (index) async {
                        Record record, next, previous;
                        if (index > _page) {
                          record = await DatabaseService.getNextRecord(
                              _record.timestamp);
                          next = await DatabaseService.getNextRecord(
                              record.timestamp);
                        } else {
                          record = await DatabaseService.getPrevRecord(
                              _record.timestamp);
                          previous = await DatabaseService.getPrevRecord(
                              record.timestamp);
                        }
                        if ((next == null &&
                                _scrollDirection == ScrollDirection.reverse) ||
                            (previous == null &&
                                _scrollDirection == ScrollDirection.forward)) {
                          setState(() {
                            _scrollable = false;
                          });
                        }
                        setState(() {
                          _record = record;
                          _next = next;
                          _previous = previous;
                        });
                        DatabaseService.incrementRecordViews(_record.id);
                        initVideoPlayer(_record.url);
                        getSinger();
                        isFollowing();
                        initLikes(record: _record, news: widget.news);
                        setState(() {
                          _page = index;
                        });
                      },
                      scrollDirection: Axis.vertical,
                      itemBuilder: (context, index) {
                        return fullscreen();
                      }),
                )
              : fullscreen(),
        ],
      ),
    );
  }

  PageController _pageController = new PageController();

  int _page = 0;
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
              child:
                  _controller != null ? VideoPlayer(_controller) : Container(),
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
                  _record != null
                      ? Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 10),
                          child: Text(
                            '@${widget.singer?.username}',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  _record != null
                      ? Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 10),
                          child: Text.rich(
                            TextSpan(children: <TextSpan>[
                              TextSpan(
                                  text: '${widget.singer?.name}\n',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text: 'singed\n',
                                  style: TextStyle(fontSize: 12)),
                              TextSpan(
                                  text: widget.melody?.name,
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ]),
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ))
                      : Container(),
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
                          InkWell(
                            onTap: () => _goToProfilePage(),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: CachedImage(
                                key: ValueKey('profile'),
                                height: 38,
                                width: 38,
                                imageShape: BoxShape.circle,
                                defaultAssetImage:
                                    Strings.default_profile_image,
                                imageUrl: widget.singer?.profileImageUrl ??
                                    Constants.startUser.profileImageUrl,
                              ),
                            ),
                          ),
                          _isFollowing
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor:
                                        MyColors.primaryColor.withOpacity(1),
                                    child: Center(
                                        child: Icon(Icons.add,
                                            size: 15, color: Colors.white)),
                                  ),
                                )
                              : Container()
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          InkWell(
                            onTap: () async {
                              if (isLikeEnabled) {
                                await likeBtnHandler(
                                    record: _record, news: widget.news);
                              }
                            },
                            child: isLiked
                                ? Icon(Icons.thumb_up,
                                    size: 35, color: MyColors.primaryColor)
                                : Icon(Icons.thumb_up,
                                    size: 35, color: Colors.white),
                          ),
                          Text('${_record?.likes ?? widget.news?.likes ?? 0}',
                              style: TextStyle(color: Colors.white))
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        //addComment();
                        if (_record != null) {
                          Navigator.of(context).pushNamed('/record-page',
                              arguments: {
                                'record': _record,
                                'is_video_visible': false
                              });
                        } else {
                          Navigator.of(context).pushNamed('/news-page',
                              arguments: {
                                'news': widget.news,
                                'is_video_visible': false
                              });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: Icon(Icons.sms,
                                    size: 35, color: Colors.white)),
                            Text(
                                '${_record?.comments ?? widget.news?.comments ?? 0}',
                                style: TextStyle(color: Colors.white))
                          ],
                        ),
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
                              child: Icon(Icons.remove_red_eye,
                                  size: 35, color: Colors.white)),
                          Text('${_record?.views ?? widget.news?.views ?? 0}',
                              style: TextStyle(color: Colors.white))
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (_record != null) {
                          AppUtil.sharePost(
                              '${widget.singer.name} singed ${widget.melody?.name}',
                              '',
                              recordId: _record.id,
                              newsId: widget.news?.id);
                        } else {
                          AppUtil.sharePost(
                              '${Constants.startUser.name} post some news', '',
                              recordId: _record?.id, newsId: widget.news?.id);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.only(bottom: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: Icon(Icons.share,
                                    size: 35, color: Colors.white)),
                            Text(
                                '${_record?.shares ?? widget.news?.shares ?? 0}',
                                style: TextStyle(color: Colors.white))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ))
      ],
    );
  }

  TextEditingController _commentController = TextEditingController();
  addComment() async {
    Navigator.of(context).push(CustomModal(
        child: Container(
      height: 200,
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _commentController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  hintText: language(en: 'New Comment', ar: 'تعليق جديد')),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_commentController.text.trim().isEmpty) {
                AppUtil.showToast('Please leave a comment');
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              if (_record != null) {
                await DatabaseService.addComment(_commentController.text,
                    recordId: _record.id);

                NotificationHandler.sendNotification(
                    _record.singerId,
                    '${Constants.currentUser.name} commented on your record',
                    _commentController.text,
                    _record.id,
                    'record_comment');
              } else if (widget.news != null) {
                await DatabaseService.addComment(_commentController.text,
                    recordId: widget.news.id);
                NotificationHandler.sendNotification(
                    Constants.startUser.id,
                    '${Constants.currentUser.name} commented on your news',
                    _commentController.text,
                    widget.news.id,
                    'news_comment');
              }
              AppUtil.showToast(
                  language(en: 'Comment Added', ar: 'تم إضافة التعليق'));
              Navigator.of(context).pop();
            },
            color: MyColors.primaryColor,
            child: Text(
              language(en: 'Add Comment', ar: 'إضافة تعليق'),
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    )));
  }
}
