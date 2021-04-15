import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/post_bottom_sheet.dart';
import 'package:Alhany/widgets/url_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class NewsItem extends StatefulWidget {
  final News news;

  const NewsItem({Key key, this.news}) : super(key: key);
  @override
  _NewsItemState createState() => _NewsItemState();
}

class _NewsItemState extends State<NewsItem> {
  bool isLiked = false;
  bool isLikeEnabled = true;
  var likes = [];

  final number = ValueNotifier(0);

  @override
  void initState() {
    if (widget.news.text.length > Sizes.postExcerpt) {
      firstHalf = widget.news.text.substring(0, Sizes.postExcerpt);
      secondHalf = widget.news.text
          .substring(Sizes.postExcerpt, widget.news.text.length);
    } else {
      firstHalf = widget.news.text;
      secondHalf = "";
    }
    if (widget.news.type == 'video') {
      initVideoPlayer();
    }
    initLikes(widget.news);
    super.initState();
  }

  void _goToProfilePage() {
    Navigator.of(context).pushNamed('/profile-page',
        arguments: {'user_id': Constants.startUser.id});
  }

  Future<void> likeBtnHandler(News news) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true) {
      await newsRef
          .doc(news.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();

      await newsRef.doc(news.id).update({'likes': FieldValue.increment(-1)});

      await NotificationHandler.removeNotification(
          Constants.startUser.id, news.id, 'like');
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isLiked == false) {
      await newsRef
          .doc(news.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await newsRef.doc(news.id).update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
      });

      await NotificationHandler.sendNotification(
          Constants.startUser.id,
          'New News Like',
          Constants.currentUser.name + ' likes your post',
          news.id,
          'news_like');
    }
    var newsMeta = await DatabaseService.getPostMeta(newsId: news.id);
    setState(() {
      news.likes = newsMeta['likes'];
      isLikeEnabled = true;
    });
  }

  void initLikes(News news) async {
    DocumentSnapshot likedSnapshot = await newsRef
        .doc(news.id)
        .collection('likes')
        ?.doc(Constants.currentUserID)
        ?.get();

    //Solves the problem setState() called after dispose()
    if (mounted) {
      setState(() {
        isLiked = likedSnapshot.exists;
      });
    }
  }

  VideoPlayerController _videoController;
  initVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.news.contentUrl);
    await _videoController.initialize();
  }

  String firstHalf;
  String secondHalf;
  bool flag = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: InkWell(
        onTap: () {
          if (Constants.currentRoute != '/news-page')
            Navigator.of(context).pushNamed('/news-page',
                arguments: {'news': widget.news, 'is_video_visible': true});
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: widget.news.text != null && widget.news.text.isNotEmpty
              ? 320
              : 305,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          child: CachedImage(
                            height: 25,
                            width: 25,
                            imageShape: BoxShape.circle,
                            imageUrl: Constants.startUser?.profileImageUrl,
                            defaultAssetImage: Strings.default_profile_image,
                          ),
                          onTap: () => _goToProfilePage(),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              child: Text(
                                '${Constants.startUser?.name}' ?? '',
                                style: TextStyle(
                                    color: MyColors.darkPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () => _goToProfilePage(),
                            ),
                            Text(
                              '${AppUtil.formatTimestamp(widget.news.timestamp)}' ??
                                  '',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Constants.isAdmin
                        ? ValueListenableBuilder<int>(
                            valueListenable: number,
                            builder: (context, value, child) {
                              return PostBottomSheet().postOptionIcon(
                                context,
                                news: widget.news,
                              );
                            },
                          )
                        : Container()
                  ],
                ),
              ),
              widget.news.text != null && widget.news.text.isNotEmpty
                  ? secondHalf.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: UrlText(
                            context: context,
                            text: widget.news.text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            urlStyle: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w400),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: UrlText(
                            context: context,
                            text: flag
                                ? (firstHalf + '...')
                                : (firstHalf + secondHalf),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            urlStyle: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w400),
                          ),
                        )
                  : Container(),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    secondHalf.isEmpty
                        ? Text('')
                        : Text(
                            flag ? 'Show more' : 'Show less',
                            style: TextStyle(color: MyColors.darkPrimaryColor),
                          )
                  ],
                ),
                onTap: () {
                  setState(() {
                    flag = !flag;
                  });
                },
              ),
              _content(),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      children: [
                        Text(
                          '${widget.news.likes ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          ' Likes, ',
                          style: TextStyle(
                              color: MyColors.primaryColor, fontSize: 12),
                        ),
                        Text(
                          '${widget.news.comments ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '  Comments, ',
                          style: TextStyle(
                              color: MyColors.primaryColor, fontSize: 12),
                        ),
                        Text(
                          '${widget.news.shares ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          ' Shares',
                          style: TextStyle(
                              color: MyColors.primaryColor, fontSize: 12),
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
                              await likeBtnHandler(widget.news);
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
                            Icons.comment,
                            size: Sizes.card_btn_size,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () => AppUtil.sharePost(
                              '${Constants.startUser.name} post some news', '',
                              newsId: widget.news.id),
                          child: SizedBox(
                            child: Icon(
                              Icons.share,
                              size: Sizes.card_btn_size,
                              color: Colors.white,
                            ),
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

  @override
  dispose() {
    if (_videoController != null) {
      _videoController.dispose();
    }
    super.dispose();
  }

  Widget playPauseBtn() {
    return InkWell(
      onTap: () =>
          Navigator.of(context).pushNamed('/post-fullscreen', arguments: {
        'news': widget.news,
      }),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              spreadRadius: 2,
              blurRadius: 4,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Icon(
          Icons.play_arrow,
          size: 35,
          color: MyColors.primaryColor,
        ),
      ),
    );
  }

  _content() {
    switch (widget.news.type) {
      case 'video':
        return Stack(
          children: [
            Container(
                height: 200,
                child: _videoController != null
                    ? VideoPlayer(_videoController)
                    : Container()),
            Positioned.fill(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                child: playPauseBtn(),
                alignment: Alignment.center,
              ),
            ))
          ],
        );
      case 'audio':
        return MusicPlayer(
          melodyList: [
            Melody(
              audioUrl: widget.news.contentUrl,
              singer: Constants.startUser.name,
              imageUrl: Constants.startUser.profileImageUrl,
            ),
          ],
          backColor: Colors.transparent,
          btnSize: 26,
          initialDuration: widget.news.duration,
          playBtnPosition: PlayBtnPosition.left,
          isCompact: true,
        );
      case 'image':
        return CachedImage(
          height: 200,
          imageShape: BoxShape.rectangle,
          imageUrl: widget.news.contentUrl,
          defaultAssetImage: Strings.default_cover_image,
        );
      default:
        return Container();
    }
  }
}
