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
import 'package:dubsmash/widgets/custom_modal.dart';
import 'package:flutter/material.dart';

import 'custom_inkwell.dart';
import 'custom_text.dart';

class CommentBottomSheet {
  Widget commentOptionIcon(BuildContext context, Record post, Comment comment, Comment parentComment) {
    return customInkWell(
        radius: BorderRadius.circular(20),
        context: context,
        onPressed: () {
          _openBottomSheet(context, post, comment, parentComment);
        },
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_drop_down),
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

  void _openBottomSheet(BuildContext context, Record record, Comment comment, Comment parentComment) async {
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
            height: Sizes.fullHeight(context) * calculateHeightRatio(isMyComment),
            width: Sizes.fullWidth(context),
            decoration: BoxDecoration(
              color: MyColors.lightPrimaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _commentOptions(context, isMyComment, record, comment, parentComment, user));
      },
    );
  }

  Widget _commentOptions(
      BuildContext context, bool isMyComment, Record record, Comment comment, Comment parentComment, User user) {
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
                text: 'Edit Comment',
                onPressed: () {
                  if (parentComment == null) {
//                    Navigator.of(context)
//                        .pushNamed('/edit-comment', arguments: {'record': record, 'user': user, 'comment': comment});
                  editComment(context, comment, record);
                  } else {
//                    Navigator.of(context).pushNamed('/edit-comment',
//                        arguments: {'record': record, 'comment': parentComment, 'reply': comment, 'user': user});
                  editReply(context, comment, parentComment, record);
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
                  color: MyColors.darkPrimaryColor,
                ),
                text: 'Delete Comment',
                onPressed: () {
                  _deleteComment(context, record.id, comment.id, parentComment == null ? null : parentComment.id);
                },
                isEnable: true,
              )
            : Container(),
        isMyComment
            ? Container()
            : _widgetBottomSheetRow(context, Icon(Icons.indeterminate_check_box), text: 'Unfollow ${user.username}',
                onPressed: () async {
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

  editComment(BuildContext context, Comment comment, Record record) async {

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
                  await DatabaseService.editComment(record.id, comment.id, _commentController.text);
                  AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
                  Navigator.of(context).pushReplacementNamed('/record-page', arguments: {'record':record});
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

  editReply(BuildContext context, Comment reply,Comment parentComment, Record record) async {

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
                  await DatabaseService.editReply(record.id, parentComment.id,reply.id, _commentController.text);
                  AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
                  Navigator.of(context).pushReplacementNamed('/comment-page', arguments: {'record':record, 'comment':parentComment});
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
                await NotificationHandler.removeNotification(user.id, Constants.currentUserID, 'follow');
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
                  color: MyColors.primaryColor,
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

  void _deleteComment(BuildContext context, String recordId, String commentId, String parentCommentId) async {
    await showDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: new AlertDialog(
          title: new Text('Are you sure?'),
          content: new Text('Do you really want to delete this comment?'),
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
                await DatabaseService.deleteComment(recordId, commentId, parentCommentId);

                await NotificationHandler.removeNotification(
                    (await DatabaseService.getRecordWithId(recordId)).singerId, recordId, 'comment');

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
    print('deleting comment!');
  }
}
