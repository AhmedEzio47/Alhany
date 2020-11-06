import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/comment_model.dart';
import 'package:Alhany/models/record.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/list_items/comment_item2.dart';
import 'package:Alhany/widgets/list_items/record_item.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecordPage extends StatefulWidget {
  final Record record;

  const RecordPage({Key key, this.record}) : super(key: key);
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  TextEditingController _commentController = TextEditingController();
  User _singer;

  getSinger() async {
    User singer = await DatabaseService.getUserWithId(widget.record.singerId);
    setState(() {
      _singer = singer;
    });
  }

  /// Submit Comment to save in firebase database
  void _submitButton() async {
    AppUtil.showLoader(context);

    if (_commentController.text.isNotEmpty) {
      DatabaseService.addComment(widget.record.id, _commentController.text);

      await NotificationHandler.sendNotification(
          widget.record.singerId,
          Constants.currentUser.name + ' commented on your post',
          _commentController.text,
          widget.record.id,
          'comment');

      await AppUtil.checkIfContainsMention(
          _commentController.text, widget.record.id);

      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            content: new Text("A comment can't be empty!"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Ok"),
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

  List<Comment> _comments = [];

  getComments() async {
    List<Comment> comments =
        await DatabaseService.getComments(widget.record.id);
    setState(() {
      _comments = comments;
    });
  }

  @override
  void initState() {
    getComments();
    getSinger();
    super.initState();
  }

  Widget sendBtn() {
    return InkWell(
        onTap: () {
          _submitButton();
          _commentController.clear();
          getComments();
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  height: 500,
                  child: Column(
                    children: [
                      RegularAppbar(context),
                      Text(
                        (_singer?.name ?? ''),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      RecordItem(
                        record: widget.record,
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 8, right: 8, top: 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: MyColors.lightPrimaryColor),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                              style: TextStyle(color: Colors.white),
                              textAlign: Constants.language == 'ar'
                                  ? TextAlign.right
                                  : TextAlign.left,
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.white),
                                hintText: language(
                                    en: Strings.en_leave_comment,
                                    ar: Strings.ar_leave_comment),
                                suffix: Constants.language == 'en'
                                    ? sendBtn()
                                    : null,
                                prefix: Constants.language == 'ar'
                                    ? sendBtn()
                                    : null,
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
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                Comment comment = _comments[index];
                                return FutureBuilder(
                                    future: DatabaseService.getUserWithId(
                                      comment.commenterID,
                                    ),
                                    builder: (BuildContext context,
                                        AsyncSnapshot snapshot) {
                                      if (!snapshot.hasData) {
                                        return SizedBox.shrink();
                                      }
                                      User commenter = snapshot.data;
                                      //print('commenter: $commenter and comment: $comment');
                                      return CommentItem2(
                                        record: widget.record,
                                        comment: comment,
                                        commenter: commenter,
                                        isReply: false,
                                      );
                                    });
                              }),
                        ),
                      )
                    ],
                  ),
                ),
              ),
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
