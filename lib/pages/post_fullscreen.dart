import 'dart:math' as math;

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostFullscreen extends StatefulWidget {
  final Record record;
  final News news;
  final User singer;
  final Melody melody;
  const PostFullscreen({Key key, this.record, this.singer, this.melody, this.news}) : super(key: key);
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

  isFollowing() async {
    if (Constants.currentUserID == widget.singer?.id) return true;

    DocumentSnapshot snapshot =
        await usersRef.document(Constants.currentUserID).collection('following').document(widget.singer?.id).get();
    return snapshot.exists;
  }

  void initLikes({Record record, News news}) async {
    CollectionReference collectionReference;
    if (record != null) {
      collectionReference = recordsRef;
    } else if (news != null) {
      collectionReference = newsRef;
    }
    DocumentSnapshot likedSnapshot = await collectionReference
        .document(record?.id ?? news?.id)
        .collection('likes')
        ?.document(Constants.currentUserID)
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
          .document(record?.id ?? news?.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();

      await collectionReference.document(record?.id ?? news?.id).updateData({'likes': FieldValue.increment(-1)});

      await NotificationHandler.removeNotification(
          record?.singerId ?? Constants.startUser.id, record?.id ?? news?.id, 'like');
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isLiked == false) {
      await collectionReference
          .document(record?.id ?? news?.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});

      await collectionReference.document(record?.id ?? news?.id).updateData({'likes': FieldValue.increment(1)});

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
    var recordMeta = await DatabaseService.getPostMeta(recordId: record?.id, newsId: news?.id);
    setState(() {
      record?.likes = recordMeta['likes'];
      news?.likes = recordMeta['likes'];
      isLikeEnabled = true;
    });
  }

  void _goToProfilePage() {
    Navigator.of(context)
        .pushNamed('/profile-page', arguments: {'user_id': widget.record?.singerId ?? Constants.startUser.id});
  }

  void _goToMelodyPage() {
    Navigator.of(context).pushNamed('/melody-page', arguments: {'melody': widget.melody});
  }

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      DatabaseService.incrementRecordViews(widget.record.id);
    } else if (widget.news != null) {
      DatabaseService.incrementNewsViews(widget.news.id);
    }
    isFollowing();
    initLikes(record: widget.record, news: widget.news);
    _controller = VideoPlayerController.network(widget.record?.audioUrl ?? widget.news?.contentUrl)
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
                  widget.record != null
                      ? Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 10),
                          child: Text(
                            '@${widget.singer?.username}',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  widget.record != null
                      ? Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 10),
                          child: Text.rich(
                            TextSpan(children: <TextSpan>[
                              TextSpan(text: '${widget.singer?.name}\n', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: 'singed\n', style: TextStyle(fontSize: 12)),
                              TextSpan(text: widget.melody?.name, style: TextStyle(fontWeight: FontWeight.bold))
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
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: Colors.black,
                                backgroundImage:
                                    NetworkImage(widget.singer?.profileImageUrl ?? Constants.startUser.profileImageUrl),
                              ),
                            ),
                          ),
                          _isFollowing
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: MyColors.primaryColor.withOpacity(1),
                                    child: Center(child: Icon(Icons.add, size: 15, color: Colors.white)),
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
                                await likeBtnHandler(record: widget.record, news: widget.news);
                              }
                            },
                            child: isLiked
                                ? Icon(Icons.thumb_up, size: 35, color: MyColors.primaryColor)
                                : Icon(Icons.thumb_up, size: 35, color: Colors.white),
                          ),
                          Text('${widget.record?.likes ?? widget.news?.likes ?? 0}',
                              style: TextStyle(color: Colors.white))
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        addComment();
                      },
                      child: Container(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: Icon(Icons.sms, size: 35, color: Colors.white)),
                            Text('${widget.record?.comments ?? widget.news?.comments ?? 0}',
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
                              child: Icon(Icons.remove_red_eye, size: 35, color: Colors.white)),
                          Text('${widget.record?.views ?? widget.news?.views ?? 0}',
                              style: TextStyle(color: Colors.white))
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
              decoration: InputDecoration(hintText: language(en: 'New Comment', ar: 'تعليق جديد')),
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
              if (widget.record != null) {
                await DatabaseService.addComment(_commentController.text, recordId: widget.record.id);

                NotificationHandler.sendNotification(
                    widget.record.singerId,
                    '${Constants.currentUser.name} commented on your record',
                    _commentController.text,
                    widget.record.id,
                    'record_comment');
              } else if (widget.news != null) {
                await DatabaseService.addComment(_commentController.text, recordId: widget.news.id);
                NotificationHandler.sendNotification(
                    Constants.startUser.id,
                    '${Constants.currentUser.name} commented on your news',
                    _commentController.text,
                    widget.news.id,
                    'new_comment');
              }
              AppUtil.showToast(language(en: 'Comment Added', ar: 'تم إضافة التعليق'));
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
