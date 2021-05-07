import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/comment_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/comment_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CommentItem2 extends StatefulWidget {
  final Record? record;
  final News? news;
  final Comment comment;
  final User commenter;
  final bool isReply;
  final Comment? parentComment;

  const CommentItem2(
      {Key? key,
      this.record,
      required this.comment,
      required this.commenter,
      required this.isReply,
      this.parentComment,
      this.news})
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
    return GestureDetector(
      onLongPress: () {
//        return ValueListenableBuilder<int>(
//          valueListenable: number,
//          builder: (context, value, child){return CommentBottomSheet().commentOptionIcon(
//              context, widget.record, widget.comment, widget.parentComment);},
//        );
        print('lol');
      },
      child: Container(
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
                      width: widget.isReply
                          ? Sizes.vsm_profile_image_w
                          : Sizes.sm_profile_image_w,
                      height: widget.isReply
                          ? Sizes.vsm_profile_image_w
                          : Sizes.sm_profile_image_h,
                      defaultAssetImage: Strings.default_profile_image,
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/profile-page', arguments: {
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
                                color: MyColors.textLightColor,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: ' ${widget.commenter.name}',
                                    style: TextStyle(
                                        color: MyColors.darkPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                TextSpan(
                                    text: ' @${widget.commenter.username}',
                                    style:
                                        TextStyle(color: Colors.grey.shade400)),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed('/profile-page', arguments: {
                              'user_id': widget.comment.commenterID,
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 2),
                          child: Text.rich(
                            TextSpan(
                                text: '',
                                children:
                                    widget.comment.text?.split(' ').map((w) {
                                  return w.startsWith('@') && w.length > 1
                                      ? TextSpan(
                                          text: ' ' + w,
                                          style: TextStyle(color: Colors.blue),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap =
                                                () => mentionedUserProfile(w),
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
                ),
                if (widget.parentComment != null &&
                    widget.record != null &&
                    widget.news != null)
                  widget.comment.commenterID == Constants.currentUserID
                      ? ValueListenableBuilder<int>(
                          valueListenable: number,
                          builder: (context, value, child) {
                            return CommentBottomSheet().commentOptionIcon(
                                context, widget.comment, widget.parentComment!,
                                record: widget.record!, news: widget.news!);
                          },
                        )
                      : Container()
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '${AppUtil.formatCommentsTimestamp(widget.comment.timestamp)}',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 12)),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                  widget.comment.likes == null
                                      ? 0.toString()
                                      : widget.comment.likes.toString(),
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (isLikeEnabled) {
                            if (!widget.isReply) {
                              await likeBtnHandler(widget.comment,
                                  record: widget.record, news: widget.news);
                            } else {
                              if (widget.parentComment?.id != null)
                                await repliesLikeBtnHandler(
                                    widget.comment, widget.parentComment!.id!,
                                    record: widget.record!, news: widget.news!);
                            }
                          }
                        },
                      ),
                      InkWell(
                        child: Row(
                          children: <Widget>[
                            InkWell(
                              onTap: () {
                                if (Constants.currentRoute != '/comment-page') {
                                  Navigator.of(context)
                                      .pushNamed('/comment-page', arguments: {
                                    'record': widget.record,
                                    'news': widget.news,
                                    'comment': widget.comment
                                  });
                                }
                              },
                              child: SizedBox(
                                  child: Image.asset(
                                Strings.reply,
                                height: Sizes.small_card_btn_size,
                                width: Sizes.small_card_btn_size,
                                color: Colors.white,
                              )),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                widget.comment.replies == null
                                    ? 0.toString()
                                    : widget.comment.replies.toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          print('Mention reply : ${widget.commenter.username}');

                          Navigator.of(context)
                              .pushNamed('/add-reply', arguments: {
                            'post': widget.record ?? widget.news,
                            'comment': widget.isReply
                                ? widget.parentComment
                                : widget.comment,
                            'user': widget.commenter,
                            'mention': widget.isReply
                                ? '@${widget.commenter.username} '
                                : '',
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
      ),
    );
  }

  Future<void> likeBtnHandler(Comment comment,
      {Record? record, News? news}) async {
    setState(() {
      isLikeEnabled = false;
    });
    CollectionReference? collectionReference;
    if (record != null) {
      collectionReference = recordsRef;
    } else if (news != null) {
      collectionReference = newsRef;
    }
    if (isLiked == true) {
      await collectionReference
          ?.doc(record?.id ?? news?.id)
          .collection('comments')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();

      await collectionReference
          ?.doc(record?.id ?? news?.id)
          .collection('comments')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
      });
    } else if (isLiked == false) {
      await collectionReference
          ?.doc(record?.id ?? news?.id)
          .collection('comments')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await collectionReference
          ?.doc(record?.id ?? news?.id)
          .collection('comments')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
      });
      if (news != null &&
          news.id != null &&
          Constants.starUser != null &&
          Constants.starUser!.id != null &&
          Constants.currentUser != null &&
          Constants.starUser!.name != null)
        await NotificationHandler.sendNotification(
            record?.singerId ?? Constants.starUser!.id!,
            'New Comment Like',
            Constants.currentUser!.name! + ' likes your comment',
            record?.id ?? news.id!,
            record != null ? 'record_like' : 'news_like');
    }
    if (widget.comment.id != null) {
      var commentMeta = await DatabaseService.getCommentMeta(widget.comment.id!,
          recordId: record?.id, newsId: news?.id);
      setState(() {
        widget.comment.likes = commentMeta['likes'];
        widget.comment.replies = commentMeta['replies'];
        isLikeEnabled = true;
      });
    }
  }

  void initLikes(Comment comment, {String? recordId, String? newsId}) async {
    CollectionReference? collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    DocumentSnapshot? likedSnapshot = await collectionReference
        ?.doc(recordId ?? newsId)
        .collection('comments')
        .doc(comment.id)
        .collection('likes')
        .doc(Constants.currentUserID)
        .get();

    //Solves the problem setState() called after dispose()
    if (mounted && likedSnapshot != null) {
      setState(() {
        isLiked = likedSnapshot.exists;
      });
    }
  }

  Future<void> repliesLikeBtnHandler(Comment comment, String parentCommentId,
      {Record? record, News? news}) async {
    setState(() {
      isLikeEnabled = false;
    });
    CollectionReference? collectionReference;
    if (record != null) {
      collectionReference = recordsRef;
    } else if (news != null) {
      collectionReference = newsRef;
    }
    if (isLiked == true && news != null) {
      await collectionReference
          ?.doc(record?.id ?? news.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();

      await collectionReference
          ?.doc(record?.id ?? news.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
      });
    } else if (isLiked == false && news != null) {
      await collectionReference
          ?.doc(record?.id ?? news.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await collectionReference
          ?.doc(record?.id ?? news.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });
      if (Constants.starUser != null &&
          Constants.starUser!.id != null &&
          Constants.currentUser != null &&
          Constants.currentUser!.name != null &&
          news.id != null)
        await NotificationHandler.sendNotification(
            record?.singerId ?? Constants.starUser!.id!,
            'New Comment Like',
            Constants.currentUser!.name! + ' likes your comment',
            record?.id ?? news.id!,
            record != null ? 'record_like' : 'news_like');
    }
    if (widget.comment.id != null && record != null && news != null) {
      var replyMeta = await DatabaseService.getReplyMeta(
          parentCommentId, widget.comment.id!,
          recordId: record.id, newsId: news.id);
      setState(() {
        widget.comment.likes = replyMeta['likes'];
        isLikeEnabled = true;
      });

      print(
          'likes = ${replyMeta['likes']} and dislikes = ${replyMeta['dislikes']}');
    }
  }

  void repliesInitLikes(Comment comment, String parentCommentId,
      {String? recordId, String? newsId}) async {
    CollectionReference? collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    DocumentSnapshot? likedSnapshot = await collectionReference
        ?.doc(recordId ?? newsId)
        .collection('comments')
        .doc(parentCommentId)
        .collection('replies')
        .doc(comment.id)
        .collection('likes')
        .doc(Constants.currentUserID)
        .get();

    //Solves the problem setState() called after dispose()
    if (mounted && likedSnapshot != null) {
      setState(() {
        isLiked = likedSnapshot.exists;
      });
    }
  }

  loadReplies(String commentId, {String? recordId, String? newsId}) async {
    List<Comment>? replies = await DatabaseService.getCommentReplies(commentId,
        recordId: recordId, newsId: newsId);
    if (mounted && replies != null) {
      setState(() {
        this.replies = replies;
      });
    }

    this.replies.forEach((element) async {
      if (element.commenterID != null) {
        User user = await DatabaseService.getUserWithId(
          element.commenterID!,
        );
        if (mounted) {
          setState(() {
            this.repliers.add(user);
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isReply) {
      initLikes(
        widget.comment,
        recordId: widget.record?.id,
        newsId: widget.news?.id,
      );
      if (widget.comment.id != null)
        loadReplies(widget.comment.id!,
            recordId: widget.record?.id, newsId: widget.news?.id);
    } else {
      if (widget.parentComment != null && widget.parentComment!.id != null)
        repliesInitLikes(widget.comment, widget.parentComment!.id!,
            recordId: widget.record?.id, newsId: widget.news?.id);
    }

    ///Set up listener here
    scrollController.addListener(() {
      if (scrollController.offset >=
              scrollController.position.maxScrollExtent &&
          !scrollController.position.outOfRange) {
        print('reached the bottom');
        //nextComments();
      } else if (scrollController.offset <=
              scrollController.position.minScrollExtent &&
          !scrollController.position.outOfRange) {
        print("reached the top");
      } else {}
    });
  }

  mentionedUserProfile(String w) async {
    String username = w.substring(1);
    User user = await DatabaseService.getUserWithUsername(username);
    Navigator.of(context)
        .pushNamed('/user-profile', arguments: {'userId': user.id});
    print(w);
  }
}
