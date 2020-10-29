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
import 'package:flutter/material.dart';

class RecordItem extends StatefulWidget {
  final Record record;

  RecordItem({Key key, this.record}) : super(key: key);

  @override
  _RecordItemState createState() => _RecordItemState();
}

class _RecordItemState extends State<RecordItem> {
  User _singer;
  Melody _melody;

  bool isLiked = false;
  bool isLikeEnabled = true;
  var likes = [];

  double _btnSize = 25;

  @override
  void initState() {
    getAuthor();
    getMelody();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 106,
        color: Colors.white.withOpacity(.4),
        child: Column(
          children: [
            ListTile(
              leading: InkWell(
                onTap: () {
                  _goToProfilePage();
                },
                child: CachedImage(
                  width: 50,
                  height: 50,
                  imageUrl: _singer?.profileImageUrl,
                  imageShape: BoxShape.rectangle,
                  defaultAssetImage: Strings.default_profile_image,
                ),
              ),
              title: Text(_singer?.name ?? ''),
              subtitle: InkWell(
                child: Text(_melody?.name ?? ''),
                onTap: () async {
                  Navigator.of(context).pushNamed('/melody-page',
                      arguments: {'melody': (await DatabaseService.getMelodyWithId(widget.record.melodyId))});
                },
              ),
            ),
            Divider(height: 2, color: MyColors.primaryColor,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                InkWell(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        child: isLiked
                            ? Icon(
                          Icons.thumb_up,
                          size: _btnSize,
                          color: MyColors.primaryColor,
                        )
                            : Icon(
                          Icons.thumb_up,
                          size: _btnSize,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          '${widget.record.likes??0}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (isLikeEnabled) {
                      await likeBtnHandler(widget.record);
                    }
                  },
                ),
                SizedBox(
                  width: 1.0,
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color:
                        MyColors.primaryColor),
                  ),
                ),
                InkWell(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: Sizes.card_btn_size,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          '${widget.record.comments??0}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
//TODO comment
//                    Navigator.of(context).pushNamed('/add-comment', arguments: {
//                      'post': post,
//                      'user': author,
//                    });
                  },
                ),
                SizedBox(
                  width: 1.0,
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color:
                        MyColors.primaryColor),
                  ),
                ),
                InkWell(
                  child: SizedBox(
                    child: Icon(
                      Icons.share,
                      size: Sizes.card_btn_size,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    //TODO share
                    //await sharePost(post.id, post.text, post.imageUrl);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> likeBtnHandler(Record record) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true) {
      await recordsRef
          .document(record.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();

      await recordsRef
          .document(record.id)
          .updateData({'likes': FieldValue.increment(-1)});

      await NotificationHandler.removeNotification(
          record.singerId, record.id, 'like');
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

      await recordsRef
          .document(record.id)
          .updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
      });

      await NotificationHandler.sendNotification(record.singerId, 'New Record Like',
          Constants.currentUser.name + ' likes your post', record.id, 'like');
    }
    var recordMeta = await DatabaseService.getRecordMeta(record.id);
    setState(() {
      record.likes = recordMeta['likes'];
      isLikeEnabled = true;
    });

  }
}
