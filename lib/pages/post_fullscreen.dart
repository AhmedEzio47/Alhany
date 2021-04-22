import 'dart:math' as math;

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:readmore/readmore.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:video_player/video_player.dart';

import 'app_page.dart';

VideoPlayerController _controller;

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
          record?.singerId ?? Constants.starUser.id,
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
          record?.singerId ?? Constants.starUser.id,
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
      'user_id': widget.record?.singerId ?? Constants.starUser.id
    });
  }

  // void _goToMelodyPage() {
  //   if (!Constants.ongoingEncoding) {
  //     Navigator.of(context).pushNamed('/melody-page',
  //         arguments: {'melody': widget.melody, 'type': Types.AUDIO});
  //   } else {
  //     AppUtil.showToast(language(
  //         ar: 'من فضلك قم برفع الفيديو السابق أولا',
  //         en: 'Please upload the previous video first'));
  //   }
  // }

  Record _record;
  ScrollDirection _scrollDirection = ScrollDirection.reverse;
  @override
  void initState() {
    super.initState();
    getMelodySinger();
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

  initVideoPlayer(String url) async {
    if (_controller != null) {
      //await _controller.dispose();
      setState(() {
        _controller = null;
      });
    }
    _controller = VideoPlayerController.network(url)
      ..addListener(() {
        // if (mounted) {
        //   setState(() {});
        // }
      })
      ..setLooping(false)
      ..initialize().then((value) {
        _controller.play();
        _controller.setLooping(false);
        print('aspect ratio: ${_controller.value.aspectRatio}');
      });
  }

  @override
  void dispose() {
    disposePlayer();
    super.dispose();
  }

  disposePlayer() async {
    await _controller.pause();
    _controller.removeListener(() {});
    await _controller.dispose();
    if (mounted) {
      setState(() {
        _controller = null;
      });
    }
  }

  Record _next, _previous;
  DragStartDetails startVerticalDragDetails;
  DragUpdateDetails updateVerticalDragDetails;

  Future<bool> _onBackPressed() {
    if (Constants.routeStack.length < 2) {
      //Constants.routeStack.removeLast();
      Constants.currentRoute = '/';
      appPageUtil.goToHome();
    } else if (Constants.routeStack[Constants.routeStack.length - 2] ==
            '/record-page' ||
        Constants.routeStack[Constants.routeStack.length - 2] ==
            '/profile-page') {
      Constants.currentRoute =
          Constants.routeStack[Constants.routeStack.length - 2];
      Constants.routeStack.removeLast();

      Navigator.of(context).pop();
    } else {
      //Constants.routeStack.removeLast();
      Constants.currentRoute = '/';
      appPageUtil.goToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
              builder: (context) => InkWell(
                  onTap: _onBackPressed,
                  child: Icon(
                    Icons.arrow_back,
                    color: MyColors.accentColor,
                  ))),
          title: Padding(
            padding: const EdgeInsets.only(right: 75),
            child: Center(
              child: Container(
                width: 120,
                child: Image.asset(
                  Strings.app_bar,
                ),
              ),
            ),
          ),
        ),
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
                        physics: !_scrollable
                            ? NeverScrollableScrollPhysics()
                            : null,
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
                                  _scrollDirection ==
                                      ScrollDirection.reverse) ||
                              (previous == null &&
                                  _scrollDirection ==
                                      ScrollDirection.forward)) {
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
                          getMelodySinger();
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
      ),
    );
  }

  PageController _pageController = new PageController();

  int _page = 0;
  Singer _melodySinger;
  getMelodySinger() async {
    Singer singer =
        await DatabaseService.getSingerWithName(widget.melody.singer);
    setState(() {
      _melodySinger = singer;
    });
  }

  fullscreen() {
    bool isTitleExpanded = false;

    return Stack(
      children: <Widget>[
        FlatButton(
            padding: EdgeInsets.all(0),
            onPressed: () {
              setState(() {
                if (play) {
                  _controller?.pause();
                  play = !play;
                } else {
                  _controller?.play();
                  play = !play;
                }
              });
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: _controller != null
                  ? AspectRatio(
                      aspectRatio: 9 / 16, child: VideoPlayer(_controller))
                  : Container(),
            )),
        Positioned.fill(
          child: Align(
            alignment: Constants.language == 'ar'
                ? Alignment.topRight
                : Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Column(
                children: [
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
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 32),
            child: Align(
              alignment: Constants.language == 'ar'
                  ? Alignment.bottomRight
                  : Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _record != null
                              ? Text(
                                  '${widget.singer?.name}',
                                  style: TextStyle(color: Colors.white),
                                )
                              : Container(),
                          _record != null
                              ? Row(
                                  children: [
                                    Directionality(
                                      textDirection: Constants.language == 'ar'
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                      child: Text(
                                        '${AppUtil.formatCommentsTimestamp(widget.record.timestamp)}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Icon(
                                      Icons.access_time,
                                      size: 15,
                                      color: MyColors.iconLightColor,
                                    )
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                      SizedBox(
                        width: 5,
                      ),
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
                            defaultAssetImage: Strings.default_profile_image,
                            imageUrl: widget.singer?.profileImageUrl ??
                                Constants.starUser.profileImageUrl,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ReadMoreText(
                    widget.record.title ?? '',
                    callback: (isMore) {
                      setState(() {
                        isTitleExpanded = !isMore;
                      });
                      print(isTitleExpanded ? 'Expanded' : 'Collapsed');
                    },
                    trimExpandedText:
                        language(ar: 'عرض القليل', en: 'show less'),
                    trimCollapsedText:
                        language(ar: 'عرض المزيد', en: 'show more'),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    // moreStyle:
                    //     TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    // lessStyle:
                    // TextStyle(fontSize: 14, fontWeight: FontWeight.bold,),
                    colorClickableText: MyColors.accentColor,

                    trimLines: 1, textAlign: TextAlign.right,
                    trimMode: TrimMode.Line,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
            padding: EdgeInsets.only(
              bottom: 70,
              right: 10,
            ),
            child: Align(
              alignment: Constants.language == 'ar'
                  ? Alignment.bottomLeft
                  : Alignment.bottomRight,
              child: Container(
                width: 70,
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
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
                                ? Icon(Icons.favorite,
                                    size: 35, color: MyColors.primaryColor)
                                : Icon(Icons.favorite,
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
                              '${Constants.starUser.name} post some news', '',
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
                                child: Icon(Icons.reply,
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
                    Constants.starUser.id,
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
