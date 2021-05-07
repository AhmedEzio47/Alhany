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
  final News? news;

  const NewsItem({Key? key, this.news}) : super(key: key);

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
    if (widget.news != null)
      setState(() {
        _news = widget.news!;
      });
    if (widget.news != null &&
        widget.news!.text != null &&
        widget.news!.text!.length > Sizes.postExcerpt) {
      firstHalf = widget.news!.text!.substring(0, Sizes.postExcerpt);
      secondHalf = widget.news!.text!
          .substring(Sizes.postExcerpt, widget.news!.text!.length);
    } else {
      if (widget.news != null && widget.news!.text != null) {
        firstHalf = widget.news!.text!;
        secondHalf = "";
      }
    }
    if (widget.news != null &&
        widget.news!.type != null &&
        widget.news!.type! == 'video') {
      initVideoPlayer();
    }
    if (widget.news != null) initLikes(widget.news!);
    super.initState();
  }

  void _goToProfilePage() {
    if (Constants.starUser != null)
      Navigator.of(context).pushNamed('/profile-page',
          arguments: {'user_id': Constants.starUser!.id});
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
      if (Constants.starUser != null &&
          Constants.starUser!.id != null &&
          news.id != null)
        await NotificationHandler.removeNotification(
            Constants.starUser!.id!, news.id!, 'like');
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

      if (Constants.starUser != null &&
          Constants.starUser!.id != null &&
          Constants.currentUser != null &&
          Constants.currentUser!.name != null &&
          news.id != null)
        await NotificationHandler.sendNotification(
            Constants.starUser!.id!,
            'New News Like',
            Constants.currentUser!.name! + ' likes your post',
            news.id!,
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
        .doc(Constants.currentUserID)
        .get();

    //Solves the problem setState() called after dispose()
    if (mounted) {
      setState(() {
        isLiked = likedSnapshot.exists;
      });
    }
  }

  VideoPlayerController? _videoController;

  initVideoPlayer() async {
    if (widget.news != null && widget.news!.contentUrl != null) {
      _videoController =
          VideoPlayerController.network(widget.news!.contentUrl!);
      await _videoController?.initialize();
    }
  }

  String? firstHalf;
  String? secondHalf;
  bool flag = true;

  News? _news;

  getNews() async {
    if (widget.news != null && widget.news!.id != null) {
      News news = await DatabaseService.getNewsWithId(widget.news!.id!);
      if (mounted)
        setState(() {
          _news = news;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: InkWell(
        onTap: () {
          AppUtil.executeFunctionIfLoggedIn(context, () async {
            if (Constants.currentRoute != '/news-page')
              await Navigator.of(context).pushNamed('/news-page',
                  arguments: {'news': _news, 'is_video_visible': true});
            await getNews();
          });
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: _news?.text != null &&
                  (_news != null && _news!.text?.isNotEmpty == true)
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
                            imageUrl: Constants.starUser?.profileImageUrl,
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
                                '${Constants.starUser?.name}',
                                style: TextStyle(
                                    color: MyColors.darkPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () => _goToProfilePage(),
                            ),
                            Text(
                              '${AppUtil.formatTimestamp(_news?.timestamp)}',
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
                              if (_news != null)
                                return PostBottomSheet().postOptionIcon(
                                  context,
                                  news: _news!,
                                );
                              return SizedBox.shrink();
                            },
                          )
                        : Container()
                  ],
                ),
              ),
              _news?.text != null &&
                      (_news != null && _news!.text?.isNotEmpty == true)
                  ? secondHalf?.isEmpty == true
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: UrlText(
                            context: context,
                            text: _news!.text!,
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
                      : firstHalf != null && secondHalf != null
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: UrlText(
                                context: context,
                                text: flag
                                    ? (firstHalf! + '...')
                                    : (firstHalf! + secondHalf!),
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
                          : SizedBox.shrink()
                  : Container(),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    secondHalf?.isEmpty == true
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
                          '${_news?.likes ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          ' Likes, ',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
                        ),
                        Text(
                          '${_news?.comments ?? 0}',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
                        ),
                        Text(
                          '  Comments, ',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
                        ),
                        Text(
                          '${_news?.shares ?? 0}',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
                        ),
                        Text(
                          ' Shares',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
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
                            AppUtil.executeFunctionIfLoggedIn(context,
                                () async {
                              if (isLikeEnabled && _news != null) {
                                await likeBtnHandler(_news!);
                              }
                            });
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
                          onTap: () => AppUtil.executeFunctionIfLoggedIn(
                              context, () async {
                            await AppUtil.sharePost(
                                '${Constants.starUser?.name} post some news',
                                '',
                                newsId: _news?.id);
                            await getNews();
                          }),
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
      _videoController?.dispose();
    }
    super.dispose();
  }

  Widget playPauseBtn() {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/post-fullscreen',
          arguments: {'news': _news, 'singer': Constants.starUser}),
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
    switch (_news?.type) {
      case 'video':
        return Stack(
          children: [
            Container(
                height: 200,
                child: _videoController != null
                    ? VideoPlayer(_videoController!)
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
        if (_news != null && _news!.duration != null)
          return MusicPlayer(
            melodyList: [
              Melody(
                audioUrl: _news?.contentUrl,
                singer: Constants.starUser?.name,
                imageUrl: Constants.starUser?.profileImageUrl,
              ),
            ],
            backColor: Colors.transparent,
            btnSize: 26,
            initialDuration: _news!.duration!,
            playBtnPosition: PlayBtnPosition.left,
            isCompact: true,
          );
        return null;
      case 'image':
        return CachedImage(
          height: 200,
          imageShape: BoxShape.rectangle,
          imageUrl: _news?.contentUrl,
          assetFit: BoxFit.fill,
          defaultAssetImage: Strings.default_cover_image,
          width: 200,
        );
      default:
        return Container();
    }
  }
}
