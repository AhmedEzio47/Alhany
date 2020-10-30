import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/sizes.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/comment_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/services/notification_handler.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CommentItem2 extends StatefulWidget {
  final Record record;
  final Comment comment;
  final User commenter;
  final bool isReply;
  final Comment parentComment;

  const CommentItem2({Key key, this.record, this.comment, this.commenter, this.isReply, this.parentComment})
      : super(key: key);

  @override
  _CommentItem2State createState() => _CommentItem2State();
}

class _CommentItem2State extends State<CommentItem2> {
  bool isLiked = false;
  bool isLikeEnabled = true;
  var likes = [];

  bool repliesVisible = false;

  List<Comment> replies = [];

  ScrollController scrollController = ScrollController();

  List<User> repliers = [];

  final number = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 3),
      decoration: BoxDecoration(color: MyColors.lightPrimaryColor),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                  child: CachedImage(
                    imageUrl: widget.commenter.profileImageUrl,
                    imageShape: BoxShape.circle,
                    width: widget.isReply ? Sizes.vsm_profile_image_w : Sizes.sm_profile_image_w,
                    height: widget.isReply ? Sizes.vsm_profile_image_w : Sizes.sm_profile_image_h,
                    defaultAssetImage: Strings.default_profile_image,
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed('/profile-page', arguments: {
                      'user_id': widget.comment.commenterID,
                    });
                  }),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.white,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                  text: ' ${widget.commenter.name}',
                                  style: TextStyle(
                                      color: MyColors.darkPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              TextSpan(
                                  text: ' @${widget.commenter.username}',
                                  style: TextStyle(color: MyColors.primaryColor)),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed('/profile-page', arguments: {
                            'user_id': widget.comment.commenterID,
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2),
                        child: Text.rich(
                          TextSpan(
                              text: '',
                              children: widget.comment.text.split(' ').map((w) {
                                return w.startsWith('@') && w.length > 1
                                    ? TextSpan(
                                        text: ' ' + w,
                                        style: TextStyle(color: Colors.blue),
                                        recognizer: TapGestureRecognizer()..onTap = () => mentionedUserProfile(w),
                                      )
                                    : TextSpan(
                                        text: ' ' + w,
                                        style: TextStyle(color: Colors.white),
                                      );
                              }).toList()),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${AppUtil.formatCommentsTimestamp(widget.comment.timestamp)}',
                    style: TextStyle(color: MyColors.primaryColor, fontSize: 12)),
                Row(
                  children: [
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          SizedBox(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(widget.comment.likes == null ? 0.toString() : widget.comment.likes.toString(),
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (isLikeEnabled) {
                          if (!widget.isReply) {
                            await likeBtnHandler(widget.record, widget.comment);
                          } else {
                            await repliesLikeBtnHandler(widget.record, widget.comment, widget.parentComment.id);
                          }
                        }
                      },
                    ),
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                              child: Image.asset(
                            Strings.reply,
                            height: Sizes.small_card_btn_size,
                            width: Sizes.small_card_btn_size,
                            color: Colors.white,
                          )),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              widget.comment.replies == null ? 0.toString() : widget.comment.replies.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        print('Mention reply : ${widget.commenter.username}');

                        Navigator.of(context).pushNamed('/add-reply', arguments: {
                          'post': widget.record,
                          'comment': widget.isReply ? widget.parentComment : widget.comment,
                          'user': widget.commenter,
                          'mention': widget.isReply ? '@${widget.commenter.username} ' : '',
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> likeBtnHandler(Record record, Comment comment) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true) {
      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();

      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
      });
    } else if (isLiked == false) {
      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});

      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
      });

      await NotificationHandler.sendNotification(record.singerId, 'New Comment Like',
          Constants.currentUser.username + ' likes your comment', record.id, 'like');
    }
    var commentMeta = await DatabaseService.getCommentMeta(record.id, widget.comment.id);
    setState(() {
      widget.comment.likes = commentMeta['likes'];
      isLikeEnabled = true;
    });
  }

  void initLikes(String recordId, Comment comment) async {
    DocumentSnapshot likedSnapshot = await recordsRef
        .document(recordId)
        .collection('comments')
        .document(comment.id)
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

  Future<void> repliesLikeBtnHandler(Record record, Comment comment, String parentCommentId) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true) {
      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(parentCommentId)
          .collection('replies')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();

      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(parentCommentId)
          .collection('replies')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
      });
    } else if (isLiked == false) {
      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(parentCommentId)
          .collection('replies')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await recordsRef
          .document(record.id)
          .collection('comments')
          .document(parentCommentId)
          .collection('replies')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(record.singerId, 'New Comment Like',
          Constants.currentUser.username + ' likes your comment', record.id, 'like');
    }
    var replyMeta = await DatabaseService.getReplyMeta(record.id, parentCommentId, widget.comment.id);
    setState(() {
      widget.comment.likes = replyMeta['likes'];
      isLikeEnabled = true;
    });

    print('likes = ${replyMeta['likes']} and dislikes = ${replyMeta['dislikes']}');
  }

  void repliesInitLikes(String recordId, Comment comment, String parentCommentId) async {
    DocumentSnapshot likedSnapshot = await recordsRef
        .document(recordId)
        .collection('comments')
        .document(parentCommentId)
        .collection('replies')
        .document(comment.id)
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

  loadReplies(String postId, String commentId) async {
    List<Comment> replies = await DatabaseService.getCommentReplies(postId, commentId);
    if (mounted) {
      setState(() {
        this.replies = replies;
      });
    }

    this.replies.forEach((element) async {
      User user = await DatabaseService.getUserWithId(
        element.commenterID,
      );
      if (mounted) {
        setState(() {
          this.repliers.add(user);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isReply) {
      initLikes(widget.record.id, widget.comment);
      loadReplies(widget.record.id, widget.comment.id);
    } else {
      repliesInitLikes(widget.record.id, widget.comment, widget.parentComment.id);
    }

    ///Set up listener here
    scrollController.addListener(() {
      if (scrollController.offset >= scrollController.position.maxScrollExtent &&
          !scrollController.position.outOfRange) {
        print('reached the bottom');
        //nextComments();
      } else if (scrollController.offset <= scrollController.position.minScrollExtent &&
          !scrollController.position.outOfRange) {
        print("reached the top");
      } else {}
    });
  }

  mentionedUserProfile(String w) async {
    String username = w.substring(1);
    User user = await DatabaseService.getUserWithUsername(username);
    Navigator.of(context).pushNamed('/user-profile', arguments: {'userId': user.id});
    print(w);
  }
}
