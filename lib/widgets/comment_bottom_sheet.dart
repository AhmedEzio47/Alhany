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
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:flutter/material.dart';

import 'custom_inkwell.dart';
import 'custom_text.dart';

class CommentBottomSheet {
  Widget commentOptionIcon(
      BuildContext context, Comment comment, Comment parentComment,
      {Record record, News news}) {
    return customInkWell(
        radius: BorderRadius.circular(20),
        context: context,
        onPressed: () {
          _openBottomSheet(context, comment, parentComment,
              record: record, news: news);
        },
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_drop_down,
            color: MyColors.textLightColor,
          ),
        ));
  }

  double calculateHeightRatio(bool isMyComment) {
    double ratio = 1.0;
    if (!isMyComment) {
      ratio = 0.17;
    } else if (isMyComment) {
      ratio = 0.2;
    }
    return ratio;
  }

  void _openBottomSheet(
      BuildContext context, Comment comment, Comment parentComment,
      {Record record, News news}) async {
    User user = await DatabaseService.getUserWithId(
      comment.commenterID,
    );
    bool isMyComment = Constants.currentUserID == comment.commenterID;
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: EdgeInsets.only(top: 5, bottom: 0),
            height:
                Sizes.fullHeight(context) * calculateHeightRatio(isMyComment),
            width: Sizes.fullWidth(context),
            decoration: BoxDecoration(
              color: MyColors.lightPrimaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _commentOptions(
                context, isMyComment, comment, parentComment, user,
                record: record, news: news));
      },
    );
  }

  Widget _commentOptions(BuildContext context, bool isMyComment,
      Comment comment, Comment parentComment, User user,
      {Record record, News news}) {
    return Column(
      children: <Widget>[
        Container(
          width: Sizes.fullWidth(context) * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        isMyComment
            ? _widgetBottomSheetRow(
                context,
                Icon(
                  Icons.edit,
                  color: MyColors.darkPrimaryColor,
                ),
                text: language(en: 'Edit Comment', ar: 'تعديل'),
                onPressed: () {
                  if (parentComment == null) {
//                    Navigator.of(context)
//                        .pushNamed('/edit-comment', arguments: {'record': record, 'user': user, 'comment': comment});
                    editComment(context, comment, record: record, news: news);
                  } else {
//                    Navigator.of(context).pushNamed('/edit-comment',
//                        arguments: {'record': record, 'comment': parentComment, 'reply': comment, 'user': user});
                    editReply(context, comment, parentComment,
                        record: record, news: news);
                  }
                },
                isEnable: false,
              )
            : Container(),
        isMyComment
            ? _widgetBottomSheetRow(
                context,
                Icon(
                  Icons.delete_forever,
                  color: MyColors.iconLightColor,
                ),
                text: language(en: 'Delete Comment', ar: 'حذف'),
                onPressed: () async {
                  await _deleteComment(context, comment.id,
                      parentComment == null ? null : parentComment.id,
                      recordId: record.id, newId: news.id);
                  if (parentComment == null) {
                    Navigator.of(context).pushReplacementNamed('/record-page',
                        arguments: {
                          'record': record,
                          'is_video_visible': true
                        });
                  } else {
                    Navigator.of(context).pushReplacementNamed('/comment-page',
                        arguments: {
                          'record': record,
                          'news': news,
                          'comment': parentComment
                        });
                  }
                },
                isEnable: true,
              )
            : Container(),
        isMyComment
            ? Container()
            : _widgetBottomSheetRow(
                context, Icon(Icons.indeterminate_check_box),
                text: 'Unfollow ${user.username}', onPressed: () async {
                unfollowUser(context, user);
              }),

//        isMyComment
//            ? Container()
//            : _widgetBottomSheetRow(
//                context,
//                Icon(Icons.volume_mute),
//                text: 'Mute ${user.username}',
//              ),
//        isMyComment
//            ? Container()
//            : _widgetBottomSheetRow(
//                context,
//                Icon(Icons.block),
//                text: 'Block ${user.username}',
//              ),
//        isMyComment
//            ? Container()
//            : _widgetBottomSheetRow(
//                context,
//                Icon(Icons.report),
//                text: 'Report Post',
//              ),
      ],
    );
  }

  TextEditingController _commentController = TextEditingController();

  editComment(BuildContext context, Comment comment,
      {Record record, News news}) async {
    _commentController.text = comment.text;

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
              decoration: InputDecoration(hintText: 'New comment'),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_commentController.text.trim().isEmpty) {
                AppUtil.showToast('Please enter some text');
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              await DatabaseService.editComment(
                  comment.id, _commentController.text,
                  recordId: record.id, newsId: news.id);
              AppUtil.showToast(
                  language(en: Strings.en_updated, ar: Strings.ar_updated));
              Navigator.of(context).pushReplacementNamed('/record-page',
                  arguments: {'record': record, 'is_video_visible': true});
            },
            color: MyColors.primaryColor,
            child: Text(
              language(en: Strings.en_update, ar: Strings.ar_update),
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    )));
  }

  editReply(BuildContext context, Comment reply, Comment parentComment,
      {Record record, News news}) async {
    _commentController.text = reply.text;

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
              decoration: InputDecoration(hintText: 'New reply'),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_commentController.text.trim().isEmpty) {
                AppUtil.showToast('Please enter some text');
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              await DatabaseService.editReply(
                  parentComment.id, reply.id, _commentController.text,
                  recordId: record.id, newsId: news.id);
              AppUtil.showToast(
                  language(en: Strings.en_updated, ar: Strings.ar_updated));
              Navigator.of(context).pushReplacementNamed('/comment-page',
                  arguments: {
                    'record': record,
                    'news': news,
                    'comment': parentComment
                  });
            },
            color: MyColors.primaryColor,
            child: Text(
              language(en: Strings.en_update, ar: Strings.ar_update),
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    )));
  }

  void unfollowUser(BuildContext context, User user) async {
    await showDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: new AlertDialog(
          title: new Text('Are you sure?'),
          content: new Text('Do you really want to unfollow ${user.username}?'),
          actions: <Widget>[
            new GestureDetector(
              onTap: () =>
                  // CLose bottom sheet
                  Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("NO"),
              ),
            ),
            SizedBox(height: 16),
            new GestureDetector(
              onTap: () async {
                AppUtil.showLoader(context);

                await DatabaseService.unfollowUser(user.id);
                await NotificationHandler.removeNotification(
                    user.id, Constants.currentUserID, 'follow');
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("YES"),
              ),
            ),
          ],
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Widget _widgetBottomSheetRow(BuildContext context, Icon icon,
      {String text, Function onPressed, bool isEnable = false}) {
    return Expanded(
      child: customInkWell(
        context: context,
        onPressed: () {
          if (onPressed != null)
            onPressed();
          else {
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              icon,
              SizedBox(
                width: 15,
              ),
              customText(
                text,
                context: context,
                style: TextStyle(
                  color: MyColors.textLightColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future _deleteComment(
      BuildContext context, String commentId, String parentCommentId,
      {String recordId, String newId}) async {
    await showDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: new AlertDialog(
          title: new Text('Are you sure?'),
          content: new Text(language(
              en: 'Do you really want to delete this comment?',
              ar: 'هل أنت متاكد من مسح التعليق؟')),
          actions: <Widget>[
            new GestureDetector(
              onTap: () =>
                  // CLose bottom sheet
                  Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(language(en: 'No', ar: 'لا ')),
              ),
            ),
            SizedBox(height: 16),
            new GestureDetector(
              onTap: () async {
                if (parentCommentId == null)
                  await DatabaseService.deleteComment(commentId,
                      recordId: recordId, newsId: newId);
                else
                  await DatabaseService.deleteReply(commentId, parentCommentId,
                      recordId: recordId, newsId: newId);

                await NotificationHandler.removeNotification(
                    (await DatabaseService.getRecordWithId(recordId)).singerId,
                    recordId,
                    'comment');

                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(language(en: 'Yes', ar: 'نعم ')),
              ),
            ),
          ],
        ),
      ),
    );
    print('deleting comment!');
  }
}
