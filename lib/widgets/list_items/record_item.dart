import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/pages/app_page.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

import '../post_bottom_sheet.dart';

class RecordItem extends StatefulWidget {
  final Record record;

  const RecordItem({Key key, this.record}) : super(key: key);

  @override
  _RecordItemState createState() => _RecordItemState();
}

class _RecordItemState extends State<RecordItem> {
  User _singer;
  Melody _melody;

  bool isLiked = false;
  bool isLikeEnabled = true;
  var likes = [];

  final number = ValueNotifier(0);

  @override
  void initState() {
    setState(() {
      _record = widget.record;
    });
    getAuthor();
    getMelody();
    initLikes(widget.record);
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  getAuthor() async {
    User author = await DatabaseService.getUserWithId(widget.record.singerId);
    if (mounted) {
      setState(() {
        _singer = author;
      });
    }
  }

  getMelody() async {
    Melody melody =
        await DatabaseService.getMelodyWithId(widget.record.melodyId);
    if (mounted) {
      setState(() {
        _melody = melody;
      });
    }
  }

  void _goToProfilePage() {
    Navigator.of(context).pushNamed('/profile-page',
        arguments: {'user_id': widget.record.singerId});
  }

  void _goToMelodyPage() {
    AppUtil.executeFunctionIfLoggedIn(context, () {
      if (!Constants.ongoingEncoding) {
        Navigator.of(context).pushNamed('/melody-page',
            arguments: {'melody': _melody, 'type': Types.AUDIO});
      } else {
        AppUtil.showToast(language(
            ar: 'من فضلك قم برفع الفيديو السابق أولا',
            en: 'Please upload the previous video first'));
      }
      ;
    });
  }

  Future<void> likeBtnHandler(Record record) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true) {
      await recordsRef
          .doc(record.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();

      await recordsRef
          .doc(record.id)
          .update({'likes': FieldValue.increment(-1)});

      await NotificationHandler.removeNotification(
          record.singerId, record.id, 'record_like');
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isLiked == false) {
      await recordsRef
          .doc(record.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await recordsRef
          .doc(record.id)
          .update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
      });

      await NotificationHandler.sendNotification(
          record.singerId,
          'New Record Like',
          Constants.currentUser.name + ' likes your post',
          record.id,
          'record_like');
    }
    var recordMeta = await DatabaseService.getPostMeta(recordId: record.id);
    setState(() {
      record.likes = recordMeta['likes'];
      isLikeEnabled = true;
    });
  }

  void initLikes(Record record) async {
    DocumentSnapshot likedSnapshot = await recordsRef
        .doc(record.id)
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

  Record _record;

  getRecord() async {
    Record record = await DatabaseService.getRecordWithId(widget.record.id);
    setState(() {
      _record = record;
    });
  }

  @override
  Widget build(BuildContext context) {
    double videoHeight = MediaQuery.of(context).size.width;
    bool isTitleExpanded = false;
    return Padding(
      padding: const EdgeInsets.only(
        top: 1,
      ),
      child: InkWell(
        onTap: () {
          AppUtil.executeFunctionIfLoggedIn(context, () async {
            if (Constants.currentRoute != '/record-page')
              await Navigator.of(context).pushNamed('/record-page', arguments: {
                'record': _record,
                'singer': _singer,
                'is_video_visible': true
              });
            await getRecord();
          });
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.1),
          ),
          child: Wrap(
            // crossAxisAlignment: Constants.language == 'ar'
            //     ? CrossAxisAlignment.end
            //     : CrossAxisAlignment.start,
            alignment: Constants.language == 'ar'
                ? WrapAlignment.end
                : WrapAlignment.start,
            children: [
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _record.singerId == Constants.currentUserID ||
                                  Constants.isAdmin
                              ? ValueListenableBuilder<int>(
                                  valueListenable: number,
                                  builder: (context, value, child) {
                                    return PostBottomSheet().postOptionIcon(
                                      context,
                                      record: _record,
                                    );
                                  },
                                )
                              : Container(),
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    style: BorderStyle.solid,
                                    color: MyColors.accentColor)),
                            child: InkWell(
                              onTap: _goToMelodyPage,
                              child: Icon(
                                Icons.mic,
                                size: 32,
                                color: MyColors.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                child: Text(' ${_singer?.name ?? ' '}',
                                    style: TextStyle(
                                        color: MyColors.textDarkColor,
                                        fontWeight: FontWeight.bold)),
                                onTap: () => _goToProfilePage(),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              InkWell(
                                child: CachedImage(
                                  height: 25,
                                  width: 25,
                                  imageShape: BoxShape.circle,
                                  imageUrl: _singer?.profileImageUrl,
                                  defaultAssetImage:
                                      Strings.default_profile_image,
                                ),
                                onTap: () => _goToProfilePage(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // LocalMusicPlayer(
              //   url: widget.record.audioUrl,
              //   backColor: Colors.transparent,
              //   btnSize: 26,
              //   recordBtnVisible: true,
              //   initialDuration: widget.record.duration,
              //   playBtnPosition: PlayBtnPosition.left,
              //   isCompact: true,
              // ),
              _record.title != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ReadMoreText(
                        _record.title ?? '',
                        callback: (isMore) {
                          setState(() {
                            isTitleExpanded = !isMore;
                          });
                          print(isTitleExpanded ? 'Expanded' : 'Collapsed');
                        },
                        trimExpandedText:
                            language(ar: 'عرض القليل', en: 'show less'),
                        trimCollapsedText:
                            language(ar: 'عرض المزيد', en: 'show more'),
                        style: TextStyle(
                            color: MyColors.textLightColor, fontSize: 16),
                        // moreStyle:
                        //     TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        // lessStyle:
                        // TextStyle(fontSize: 14, fontWeight: FontWeight.bold,),
                        colorClickableText: MyColors.accentColor,

                        trimLines: 2, textAlign: TextAlign.right,
                        trimMode: TrimMode.Line,
                      ),
                    )
                  : Container(),
              SizedBox(
                width: _record.title != null ? 5 : 0,
              ),
              Stack(
                children: [
                  Container(
                      height: videoHeight,
                      child: _record.thumbnailUrl != null
                          ? Stack(
                              children: [
                                CachedImage(
                                  height: videoHeight + 50,
                                  width: MediaQuery.of(context).size.width,
                                  imageShape: BoxShape.rectangle,
                                  imageUrl: _record.thumbnailUrl,
                                  defaultAssetImage:
                                      Strings.default_cover_image,
                                  assetFit: BoxFit.fill,
                                ),
                                Positioned.fill(
                                    child: Align(
                                  child: playBtn(),
                                  alignment: Alignment.center,
                                ))
                              ],
                            )
                          : Stack(
                              children: [
                                Image.asset(
                                  Strings.default_cover_image,
                                  height: videoHeight,
                                  fit: BoxFit.fitHeight,
                                ),
                                Positioned.fill(
                                    child: Align(
                                  child: playBtn(),
                                  alignment: Alignment.center,
                                ))
                              ],
                            )),
                  Positioned.fill(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      child: playPauseBtn(),
                      alignment: Alignment.center,
                    ),
                  ))
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Padding(
                    //   padding: const EdgeInsets.only(left: 10.0),
                    //   child: Row(
                    //     children: [
                    //       Text(
                    //         '${widget.record.likes ?? 0}',
                    //         style: TextStyle(color: Colors.white, fontSize: 12),
                    //       ),
                    //       Text(
                    //         ' Likes, ',
                    //         style: TextStyle(
                    //             color: MyColors.textLightColor, fontSize: 12),
                    //       ),
                    //       Text(
                    //         '${widget.record.comments ?? 0}',
                    //         style: TextStyle(color: Colors.white, fontSize: 12),
                    //       ),
                    //       Text(
                    //         '  Comments, ',
                    //         style: TextStyle(
                    //             color: MyColors.textLightColor, fontSize: 12),
                    //       ),
                    //       Text(
                    //         '${widget.record.shares ?? 0}',
                    //         style: TextStyle(color: Colors.white, fontSize: 12),
                    //       ),
                    //       Text(
                    //         ' Shares',
                    //         style: TextStyle(
                    //             color: MyColors.textLightColor, fontSize: 12),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Directionality(
                        textDirection: Constants.language == 'ar'
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: Text(
                          '${_record.views ?? 0} ${language(en: 'views', ar: 'مشاهدة')}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () =>
                                AppUtil.executeFunctionIfLoggedIn(context, () {
                              AppUtil.sharePost(
                                  ' ${_singer.name} singed ${_melody.name} ',
                                  '',
                                  recordId: _record.id);
                            }),
                            child: SizedBox(
                              child: Icon(
                                Icons.reply,
                                size: Sizes.card_btn_size,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            '${_record.comments ?? 0}',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(
                            width: 5,
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
                          Text(
                            '${_record.likes ?? 0}',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          InkWell(
                            onTap: () async {
                              AppUtil.executeFunctionIfLoggedIn(context,
                                  () async {
                                if (isLikeEnabled) {
                                  await likeBtnHandler(_record);
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

                          // SizedBox(
                          //   width: 10,
                          // ),
                          // InkWell(
                          //   onTap: () =>
                          //       AppUtil.executeFunctionIfLoggedIn(context, () {
                          //     AppUtil.sharePost(
                          //         ' ${_singer.name} singed ${_melody.name} ', '',
                          //         recordId: widget.record.id);
                          //   }),
                          //   child: SizedBox(
                          //     child: Icon(
                          //       Icons.share,
                          //       size: Sizes.card_btn_size,
                          //       color: Colors.white,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget playPauseBtn() {
    return InkWell(
      onTap: () {
        print('tapped 2');
        if (Constants.currentRoute == '/record-page' ||
            Constants.currentRoute == '/profile-page') {
          Navigator.of(context).pushNamed('/post-fullscreen', arguments: {
            'record': _record,
            'singer': _singer,
            'melody': _melody
          });
        } else {
          appPageUtil.goToFullscreen(_record, _singer, _melody);
        }
      },
      child: Icon(
        Icons.play_arrow,
        size: 60,
        color: MyColors.iconLightColor,
      ),
    );
  }

  playBtn() {
    return InkWell(
      onTap: () {
        print('tapped');
        if (Constants.currentRoute == '/record-page' ||
            Constants.currentRoute == '/profile-page') {
          Navigator.of(context).pushNamed('/post-fullscreen', arguments: {
            'record': _record,
            'singer': _singer,
            'melody': _melody
          });
        } else {
          appPageUtil.goToFullscreen(_record, _singer, _melody);
        }
      },
      child: Icon(
        Icons.play_arrow,
        size: 40,
        color: MyColors.primaryColor,
      ),
    );
  }
}
