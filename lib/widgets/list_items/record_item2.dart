import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/sizes.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/services/notification_handler.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:dubsmash/widgets/music_player.dart';
import 'package:flutter/material.dart';

class RecordItem2 extends StatefulWidget {
  final Record record;

  const RecordItem2({Key key, this.record}) : super(key: key);

  @override
  _RecordItem2State createState() => _RecordItem2State();
}

class _RecordItem2State extends State<RecordItem2> {
  User _singer;
  Melody _melody;

  bool isLiked = false;
  bool isLikeEnabled = true;
  var likes = [];

  @override
  void initState() {
    getAuthor();
    getMelody();
    initLikes(widget.record);
    super.initState();
  }

  getAuthor() async {
    User author = await DatabaseService.getUserWithId(widget.record.singerId);
    setState(() {
      _singer = author;
    });
  }

  getMelody() async {
    Melody melody = await DatabaseService.getMelodyWithId(widget.record.melodyId);
    setState(() {
      _melody = melody;
    });
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

      await NotificationHandler.sendNotification(
          record.singerId, 'New Record Like', Constants.currentUser.name + ' likes your post', record.id, 'like');
    }
    var recordMeta = await DatabaseService.getRecordMeta(record.id);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: ()=> Navigator.of(context).pushNamed('/record-page', arguments: {'record':widget.record}),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 120,
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
              Divider(
                height: 1,
                thickness: 3,
                color: MyColors.primaryColor,
              ),
              MusicPlayer(
                url: widget.record.audioUrl,
                backColor: Colors.transparent,
                btnSize: 26,
                recordBtnVisible: true,
                initialDuration: widget.record.duration,
                playBtnPosition: PlayBtnPosition.left,
                isCompact: true,
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
                          ' Shares, ',
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
                            Icons.chat_bubble_outline,
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
}
