import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/comment_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/list_items/comment_item.dart';
import 'package:Alhany/widgets/list_items/record_item.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class RecordPage extends StatefulWidget {
  final Record record;
  final bool isVideoVisible;
  const RecordPage({Key key, this.record, this.isVideoVisible = true})
      : super(key: key);
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
      DatabaseService.addComment(
        _commentController.text,
        recordId: widget.record.id,
      );

      await NotificationHandler.sendNotification(
          widget.record.singerId,
          Constants.currentUser.name + ' commented on your post',
          _commentController.text,
          widget.record.id,
          'record_comment');

      await AppUtil.checkIfContainsMention(
          _commentController.text, widget.record.id);
      Constants.currentRoute = '';
      Navigator.pop(context);
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
                  Constants.currentRoute = '';
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    Constants.currentRoute = '';
    Navigator.of(context).pop();
  }

  List<Comment> _comments = [];

  getComments() async {
    List<Comment> comments =
        await DatabaseService.getComments(recordId: widget.record.id);
    setState(() {
      _comments = comments;
    });
  }

  getAllComments() async {
    List<Comment> comments =
        await DatabaseService.getAllComments(recordId: widget.record.id);
    setState(() {
      _comments = comments;
    });
  }

  LinkedScrollControllerGroup _controllers;
  ScrollController _commentsScrollController = ScrollController();
  ScrollController _pageScrollController = ScrollController();
  @override
  void initState() {
    _controllers = LinkedScrollControllerGroup();
    _commentsScrollController = _controllers.addAndGet();
    _pageScrollController = _controllers.addAndGet();
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
      child: SafeArea(
        child: Scaffold(
          body: Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: new LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  MyColors.primaryColor,
                ],
              ),
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
                  controller: _pageScrollController,
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      children: [
                        RegularAppbar(context),
                        SizedBox(
                          height: 10,
                        ),
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              SliverList(
                                delegate: SliverChildListDelegate([
                                  widget.isVideoVisible
                                      ? RecordItem(
                                          record: widget.record,
                                        )
                                      : Container(),
                                  ListView.separated(
                                      controller: _commentsScrollController,
                                      separatorBuilder: (context, index) {
                                        return Divider(
                                          height: 2,
                                          thickness: 2,
                                          color: Colors.transparent,
                                        );
                                      },
                                      shrinkWrap: true,
                                      itemCount: _comments.length + 1,
                                      itemBuilder: (context, index) {
                                        Comment comment = Comment();
                                        if (index < _comments.length) {
                                          comment = _comments[index];
                                        }
                                        return index < _comments.length
                                            ? FutureBuilder(
                                                future: DatabaseService
                                                    .getUserWithId(
                                                  comment.commenterID,
                                                ),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return SizedBox.shrink();
                                                  }
                                                  User commenter =
                                                      snapshot.data;
                                                  //print('commenter: $commenter and comment: $comment');

                                                  return CommentItem2(
                                                    record: widget.record,
                                                    comment: comment,
                                                    commenter: commenter,
                                                    isReply: false,
                                                  );
                                                })
                                            : _comments.length > 20
                                                ? InkWell(
                                                    onTap: () async {
                                                      AppUtil.showLoader(
                                                          context);
                                                      await getAllComments();
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Center(
                                                          child: Text(
                                                        'show all',
                                                        style: TextStyle(
                                                            color: MyColors
                                                                .accentColor,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline),
                                                      )),
                                                    ),
                                                  )
                                                : Container();
                                      }),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: EdgeInsets.only(
                                left: 8, right: 8, top: 8, bottom: 8),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30.0),
                                color: MyColors.lightPrimaryColor),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  dispose() {
    _pageScrollController.dispose();
    _commentsScrollController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() {
    Constants.currentRoute = '';
    Constants.routeStack.removeLast();
    Navigator.of(context).pop();
  }
}
