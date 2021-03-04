import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/comment_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/list_items/comment_item.dart';
import 'package:Alhany/widgets/list_items/news_item.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  final News news;

  final bool isVideoVisible;

  const NewsPage({Key key, this.news, this.isVideoVisible = true})
      : super(key: key);
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  TextEditingController _commentController = TextEditingController();

  /// Submit Comment to save in firebase database
  void _submitButton() async {
    AppUtil.showLoader(context);

    if (_commentController.text.isNotEmpty) {
      DatabaseService.addComment(_commentController.text,
          newsId: widget.news.id);

      await NotificationHandler.sendNotification(
          Constants.starUser.id,
          Constants.currentUser.name + ' commented on your post',
          _commentController.text,
          widget.news.id,
          'news_comment');

      await AppUtil.checkIfContainsMention(
          _commentController.text, widget.news.id);

      Constants.currentRoute = '';
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
        await DatabaseService.getComments(newsId: widget.news.id);
    setState(() {
      _comments = comments;
    });
  }

  getAllComments() async {
    List<Comment> comments =
        await DatabaseService.getAllComments(newsId: widget.news.id);
    setState(() {
      _comments = comments;
    });
  }

  @override
  void initState() {
    getComments();
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
            gradient: new LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  MyColors.primaryColor,
                ]),
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
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: [
                      RegularAppbar(context),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildListDelegate([
                                widget.isVideoVisible
                                    ? NewsItem(
                                        news: widget.news,
                                      )
                                    : Container(),
                                ListView.separated(
                                    separatorBuilder: (context, index) {
                                      return Divider(
                                        height: 2,
                                        thickness: 2,
                                        color: Colors.transparent,
                                      );
                                    },
                                    shrinkWrap: true,
                                    primary: false,
                                    itemCount: _comments.length + 1,
                                    itemBuilder: (context, index) {
                                      Comment comment = Comment();
                                      if (index < _comments.length) {
                                        comment = _comments[index];
                                      }
                                      return index < _comments.length
                                          ? FutureBuilder(
                                              future:
                                                  DatabaseService.getUserWithId(
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
                                                  news: widget.news,
                                                  comment: comment,
                                                  commenter: commenter,
                                                  isReply: false,
                                                );
                                              })
                                          : _comments.length > 20
                                              ? InkWell(
                                                  onTap: () async {
                                                    AppUtil.showLoader(context);
                                                    await getAllComments();
                                                    Navigator.of(context).pop();
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
                      ),
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
