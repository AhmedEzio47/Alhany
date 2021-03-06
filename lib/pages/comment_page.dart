import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/comment_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/list_items/comment_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentPage extends StatefulWidget {
  final Record record;
  final News news;
  final Comment comment;
  const CommentPage({Key key, this.record, this.news, this.comment})
      : super(key: key);

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  TextEditingController _replyController = TextEditingController();
  ScrollController _repliesScrollController = ScrollController();
  void _submitButton() async {
    AppUtil.showLoader(context);

    if (_replyController.text.isNotEmpty) {
      DatabaseService.addReply(widget.comment.id, _replyController.text,
          recordId: widget.record?.id, newsId: widget.news?.id);

      await NotificationHandler.sendNotification(
          widget.record?.singerId ?? Constants.starUser.id,
          Constants.currentUser.name + ' commented on your post',
          _replyController.text,
          widget.record?.id ?? widget.news?.id,
          widget.record != null ? 'record_comment' : 'news_comment');

      await AppUtil.checkIfContainsMention(
          _replyController.text, widget.record?.id);

      _onBackPressed();
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            content: new Text(language(
                en: "A comment can't be empty!", ar: 'التعليق لا يكون فارغا')),
            actions: <Widget>[
              new FlatButton(
                child: new Text(language(en: "Ok", ar: 'موافق')),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    Navigator.of(context).pop();
  }

  List<Comment> _replies = [];
  Timestamp lastVisiblePostSnapShot;

  getReplies() async {
    List<Comment> replies = await DatabaseService.getCommentReplies(
        widget.comment.id,
        recordId: widget.record?.id,
        newsId: widget.news?.id);

    setState(() {
      _replies = replies;
      this.lastVisiblePostSnapShot = replies.last.timestamp;
    });
  }

  nextReplies() async {
    List<Comment> replies = await DatabaseService.getNextCommentReplies(
        widget.comment.id, lastVisiblePostSnapShot,
        recordId: widget.record?.id, newsId: widget.news?.id);
    if (replies.length > 0) {
      setState(() {
        replies.forEach((element) => _replies.add(element));
        this.lastVisiblePostSnapShot = replies.last.timestamp;
      });
    }
  }

  @override
  void initState() {
    _repliesScrollController
      ..addListener(() {
        if (_repliesScrollController.offset >=
                _repliesScrollController.position.maxScrollExtent &&
            !_repliesScrollController.position.outOfRange) {
          print('reached the bottom');
          nextReplies();
        } else if (_repliesScrollController.offset <=
                _repliesScrollController.position.minScrollExtent &&
            !_repliesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    getReplies();
    super.initState();
  }

  Widget sendBtn() {
    return InkWell(
        onTap: () {
          _submitButton();
          _replyController.clear();
          getReplies();
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            Constants.language == 'en' ? Strings.send : Strings.send_ar,
            scale: .8,
            color: MyColors.darkPrimaryColor,
          ),
        ));
  }

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: MyColors.primaryColor,
            image: DecorationImage(
              colorFilter: new ColorFilter.mode(
                  Colors.black.withOpacity(0.1), BlendMode.dstATop),
              image: AssetImage(Strings.default_bg),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 40,
              ),
              FutureBuilder(
                  future: DatabaseService.getUserWithId(
                    widget.comment.commenterID,
                  ),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox.shrink();
                    }
                    User commenter = snapshot.data;
                    //print('commenter: $commenter and comment: $comment');
                    return CommentItem2(
                      record: widget.record,
                      news: widget.news,
                      comment: widget.comment,
                      commenter: commenter,
                      isReply: false,
                    );
                  }),
              Container(
                margin: EdgeInsets.only(left: 8, right: 8, top: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    color: MyColors.lightPrimaryColor),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                      style: TextStyle(color: MyColors.textLightColor),
                      textAlign: Constants.language == 'ar'
                          ? TextAlign.right
                          : TextAlign.left,
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: MyColors.textLightColor),
                        hintText: language(
                            en: Strings.en_leave_reply,
                            ar: Strings.ar_leave_reply),
                        suffix: Constants.language == 'en' ? sendBtn() : null,
                        prefix: Constants.language == 'ar' ? sendBtn() : null,
                      )),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(),
                  child: ListView.separated(
                      separatorBuilder: (context, index) {
                        return Divider(
                          height: 2,
                          thickness: 2,
                          color: Colors.transparent,
                        );
                      },
                      controller: _repliesScrollController,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: _replies.length,
                      itemBuilder: (context, index) {
                        Comment comment = _replies[index];
                        return FutureBuilder(
                            future: DatabaseService.getUserWithId(
                              comment.commenterID,
                            ),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox.shrink();
                              }
                              User commenter = snapshot.data;
                              //print('commenter: $commenter and comment: $comment');
                              return CommentItem2(
                                record: widget.record,
                                news: widget.news,
                                comment: comment,
                                commenter: commenter,
                                parentComment: widget.comment,
                                isReply: true,
                              );
                            });
                      }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() {
    Constants.currentRoute = '';
    Navigator.of(context).pop();
  }
}
