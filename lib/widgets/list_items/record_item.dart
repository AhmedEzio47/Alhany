import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecordItem extends StatefulWidget {
  final Record record;

  const RecordItem({Key key, this.record}) : super(key: key);

  @override
  _RecordItemState createState() => _RecordItemState();
}

class _RecordItemState extends State<RecordItem> {
  User _singer;
  Melody _melody;

  bool isLiked = false;
  bool isLikeEnabled = true;
  var likes = [];

  bool _isVideoPlaying = false;

  @override
  void initState() {
    getAuthor();
    getMelody();
    initVideoPlayer();
    initLikes(widget.record);
    super.initState();
  }

  getAuthor() async {
    User author = await DatabaseService.getUserWithId(widget.record.singerId);
    if (mounted) {
      setState(() {
        _singer = author;
      });
    }
  }

  getMelody() async {
    Melody melody = await DatabaseService.getMelodyWithId(widget.record.melodyId);
    if (mounted) {
      setState(() {
        _melody = melody;
      });
    }
  }

  void _goToProfilePage() {
    Navigator.of(context).pushNamed('/profile-page', arguments: {'user_id': widget.record.singerId});
  }

  void _goToMelodyPage() {
    Navigator.of(context).pushNamed('/melody-page', arguments: {'melody': _melody});
  }

  Future<void> likeBtnHandler(Record record) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true) {
      await recordsRef.document(record.id).collection('likes').document(Constants.currentUserID).delete();

      await recordsRef.document(record.id).updateData({'likes': FieldValue.increment(-1)});

      await NotificationHandler.removeNotification(record.singerId, record.id, 'like');
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isLiked == false) {
      await recordsRef
          .document(record.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});

      await recordsRef.document(record.id).updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
      });

      await NotificationHandler.sendNotification(record.singerId, 'New Record Like',
          Constants.currentUser.name + ' likes your post', record.id, 'record_like');
    }
    var recordMeta = await DatabaseService.getPostMeta(recordId: record.id);
    setState(() {
      record.likes = recordMeta['likes'];
      isLikeEnabled = true;
    });
  }

  void initLikes(Record record) async {
    DocumentSnapshot likedSnapshot =
        await recordsRef.document(record.id).collection('likes')?.document(Constants.currentUserID)?.get();

    //Solves the problem setState() called after dispose()
    if (mounted) {
      setState(() {
        isLiked = likedSnapshot.exists;
      });
    }
  }

  VideoPlayerController _videoController;
  initVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.record.audioUrl);
    await _videoController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          if (Constants.currentRoute != '/record-page')
            Navigator.of(context).pushNamed('/record-page', arguments: {'record': widget.record, 'singer': _singer});
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: new BorderRadius.circular(10.0),
            color: Colors.white.withOpacity(.4),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    InkWell(
                      child: CachedImage(
                        height: 25,
                        width: 25,
                        imageShape: BoxShape.circle,
                        imageUrl: _singer?.profileImageUrl,
                        defaultAssetImage: Strings.default_profile_image,
                      ),
                      onTap: () => _goToProfilePage(),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    InkWell(
                      child: Text(
                        _singer?.name ?? '',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onTap: () => _goToProfilePage(),
                    ),
                    Text(
                      ' singed ',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    InkWell(
                      child: Text(
                        _melody?.name ?? '',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onTap: () => _goToMelodyPage(),
                    ),
                  ],
                ),
              ),
              // MusicPlayer(
              //   url: widget.record.audioUrl,
              //   backColor: Colors.transparent,
              //   btnSize: 26,
              //   recordBtnVisible: true,
              //   initialDuration: widget.record.duration,
              //   playBtnPosition: PlayBtnPosition.left,
              //   isCompact: true,
              // ),
              Stack(
                children: [
                  Container(height: 200, child: _videoController != null ? VideoPlayer(_videoController) : Container()),
                  Positioned.fill(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      child: playPauseBtn(),
                      alignment: Alignment.center,
                    ),
                  ))
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      children: [
                        Text(
                          '${widget.record.likes ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          ' Likes, ',
                          style: TextStyle(color: MyColors.primaryColor, fontSize: 12),
                        ),
                        Text(
                          '${widget.record.comments ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '  Comments, ',
                          style: TextStyle(color: MyColors.primaryColor, fontSize: 12),
                        ),
                        Text(
                          '${widget.record.shares ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          ' Shares',
                          style: TextStyle(color: MyColors.primaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            if (isLikeEnabled) {
                              await likeBtnHandler(widget.record);
                            }
                          },
                          child: SizedBox(
                            child: isLiked
                                ? Icon(
                                    Icons.thumb_up,
                                    size: Sizes.card_btn_size,
                                    color: MyColors.primaryColor,
                                  )
                                : Icon(
                                    Icons.thumb_up,
                                    size: Sizes.card_btn_size,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          child: Icon(
                            Icons.comment,
                            size: Sizes.card_btn_size,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          child: Icon(
                            Icons.share,
                            size: Sizes.card_btn_size,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget playPauseBtn() {
    return InkWell(
      onTap: () => Navigator.of(context)
          .pushNamed('/post-fullscreen', arguments: {'record': widget.record, 'singer': _singer, 'melody': _melody}),
      child: Container(
        height: 40,
        width: 40,
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
          size: 35,
          color: MyColors.primaryColor,
        ),
      ),
    );
  }
}
