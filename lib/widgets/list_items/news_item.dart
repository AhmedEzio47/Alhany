import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/local_music_player.dart';
import 'package:Alhany/widgets/post_bottom_sheet.dart';
import 'package:Alhany/widgets/url_text.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
    setState(() {
      _news = widget.news;
    });
    if (widget.news.text.length > Sizes.postExcerpt) {
      firstHalf = widget.news.text.substring(0, Sizes.postExcerpt);
      secondHalf = widget.news.text
          .substring(Sizes.postExcerpt, widget.news.text.length);
    } else {
      firstHalf = widget.news.text;
      secondHalf = "";
    }
    if (widget.news.type == 'video') {
      if (Constants.currentRoute == '/news-page' &&
          widget.news.type == 'video') {
        initVideoPlayer(widget.news.contentUrl);
        setState(() {
          _isPlaying = true;
        });
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    }
    initLikes(widget.news);
    super.initState();
  }

  void _goToProfilePage() {
    Navigator.of(context).pushNamed('/profile-page',
        arguments: {'user_id': Constants.starUser.id});
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
          Constants.starUser.id, news.id, 'like');
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
          Constants.starUser.id,
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

  String firstHalf;
  String secondHalf;
  bool flag = true;

  News _news;
  getNews() async {
    News news = await DatabaseService.getNewsWithId(widget.news.id);
    setState(() {
      _news = news;
    });
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
          height: _news.text != null && _news.text.isNotEmpty ? 320 : 305,
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
                                '${Constants.starUser?.name}' ?? '',
                                style: TextStyle(
                                    color: MyColors.darkPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () => _goToProfilePage(),
                            ),
                            Text(
                              '${AppUtil.formatTimestamp(_news.timestamp)}' ??
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
                                news: _news,
                              );
                            },
                          )
                        : Container()
                  ],
                ),
              ),
              _news.text != null && _news.text.isNotEmpty
                  ? secondHalf.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: UrlText(
                            context: context,
                            text: _news.text,
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
                          '${_news.likes ?? 0}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          ' Likes, ',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
                        ),
                        Text(
                          '${_news.comments ?? 0}',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
                        ),
                        Text(
                          '  Comments, ',
                          style: TextStyle(
                              color: MyColors.textLightColor, fontSize: 12),
                        ),
                        Text(
                          '${_news.shares ?? 0}',
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
                              if (isLikeEnabled) {
                                await likeBtnHandler(_news);
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
                                '${Constants.starUser.name} post some news', '',
                                newsId: _news.id);
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
      _videoController.dispose();
    }

    if (_chewieController != null) {
      _chewieController.dispose();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Widget playPauseBtn() {
    return InkWell(
      onTap: () {
        if (Constants.currentRoute != '/news-page') {
          Navigator.of(context).pushNamed('/news-page', arguments: {
            'news': _news,
          });
          Constants.currentRoute = '/news-page';
        } else {
          playVideo();
        }
      },
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
    switch (_news.type) {
      case 'video':
        return Stack(
          children: [
            Constants.currentRoute == '/news-page'
                ? InkWell(
                    onTap: playVideo,
                    child: Container(
                        height: 200,
                        child: _videoController != null &&
                                _chewieController != null
                            ? Chewie(
                                controller: _chewieController,
                              )
                            : Container()),
                  )
                : CachedImage(
                    imageUrl: _news.thumbnail,
                    width: MediaQuery.of(context).size.width,
                    imageShape: BoxShape.rectangle,
                    defaultAssetImage: Strings.default_cover_image,
                    height: 200,
                  ),
            !_isPlaying
                ? Positioned.fill(
                    child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      child: playPauseBtn(),
                      alignment: Alignment.center,
                    ),
                  ))
                : Container()
          ],
        );
      case 'audio':
        return ChangeNotifierProvider(
          create: (context) => MyAudioPlayer(),
          child: LocalMusicPlayer(
            melodyList: [
              Melody(
                songUrl: _news.contentUrl,
                singer: Constants.starUser.name,
                imageUrl: Constants.starUser.profileImageUrl,
              ),
            ],
            backColor: Colors.transparent,
            btnSize: 26,
            initialDuration: _news.duration,
            playBtnPosition: PlayBtnPosition.left,
            isCompact: true,
          ),
        );
      case 'image':
        return CachedImage(
          height: 200,
          imageShape: BoxShape.rectangle,
          imageUrl: _news.contentUrl,
          assetFit: BoxFit.fill,
          defaultAssetImage: Strings.default_cover_image,
        );
      default:
        return Container();
    }
  }

  bool _isPlaying;
  var _chewieController;

  initVideoPlayer(String url) async {
    if (_videoController != null) {
      //await _controller.dispose();
      setState(() {
        _videoController = null;
      });
    }
    _videoController = VideoPlayerController.network(url)
      ..addListener(() {
        // if (mounted) {
        //   setState(() {});
        // }
      })
      ..setLooping(false)
      ..initialize().then((value) {
        _videoController.play();
        _chewieController = ChewieController(
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
          showControls: true,
          videoPlayerController: _videoController,
          autoPlay: false,
          looping: true,
        );
        setState(() {
          _isPlaying = true;
        });
        _videoController.setLooping(false);

        // final playerWidget = Chewie(
        //   controller: _chewieController,
        // );
        print('aspect ratio: ${_videoController.value.aspectRatio}');
      });
  }

  disposePlayer() async {
    await _videoController.pause();
    _videoController.removeListener(() {});
    await _videoController.dispose();
    if (mounted) {
      _videoController = null;
    }
  }

  void playVideo() {
    if (_isPlaying) {
      _videoController.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      _videoController.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }
}
