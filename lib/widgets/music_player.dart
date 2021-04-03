import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/permissions_service.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stripe_payment/stripe_payment.dart';

enum PlayerState { stopped, playing, paused }
enum PlayBtnPosition { bottom, left }

class MusicPlayer extends StatefulWidget {
  final List<Melody> melodyList;
  final Color backColor;
  final Function onComplete;
  final bool isLocal;
  final String title;
  final double btnSize;
  final int initialDuration;
  final PlayBtnPosition playBtnPosition;
  final bool isCompact;
  final bool isRecordBtnVisible;

  MusicPlayer(
      {Key key,
      this.backColor,
      this.onComplete,
      this.isLocal = false,
      this.title,
      this.btnSize = 40.0,
      this.initialDuration,
      this.playBtnPosition = PlayBtnPosition.bottom,
      this.isCompact = false,
      this.melodyList,
      this.isRecordBtnVisible = false})
      : super(key: key);

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  void initState() {
    initAudioService();
    if (widget.melodyList[audioServiceIndex]?.isSong ?? true) {
      choices = [
        language(en: Strings.en_edit_image, ar: Strings.ar_edit_image),
        language(en: Strings.en_edit_name, ar: Strings.ar_edit_name),
        language(en: Strings.en_delete, ar: Strings.ar_delete)
      ];
    } else {
      choices = [
        language(en: Strings.en_edit_lyrics, ar: Strings.ar_edit_lyrics),
        language(en: Strings.en_edit_image, ar: Strings.ar_edit_image),
        language(en: Strings.en_edit_name, ar: Strings.ar_edit_name),
        language(en: Strings.en_delete, ar: Strings.ar_delete)
      ];
    }

    super.initState();
  }

  initAudioService() async {
    List<Map<String, dynamic>> melodiesMapList =
        widget.melodyList.map((doc) => doc.toMap()).toList();
    if (!AudioService.connected) await AudioService.connect();
    await AudioService.start(
      backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
      androidNotificationChannelName: 'Audio Service Demo',
      // Enable this if you want the Android service to exit the foreground state on pause.
      //androidStopForegroundOnPause: true,
      androidNotificationColor: 0xFF2196f3,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidEnableQueue: true,
    );
    await AudioService.customAction('clearMediaLibrary', []);
    for (int i = 0; i < melodiesMapList.length; i++) {
      await AudioService.customAction(
          'addMediaSources', jsonEncode(melodiesMapList[i]));
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await isFavourite();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AudioService.runningStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active) {
          // Don't show anything until we've ascertained whether or not the
          // service is running, since we want to show a different UI in
          // each case.
          return SizedBox();
        }
        final running = snapshot.data ?? false;
        return running
            ? Container(
                height: 200,
                padding: EdgeInsets.all(0),
                child: Padding(
                  padding: EdgeInsets.all(widget.isCompact ? 8 : 18),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: new BorderRadius.circular(20.0),
                      color: widget.backColor,
                    ),
                    child: Center(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        widget.isCompact
                            ? Container()
                            : SizedBox(
                                height: 5,
                              ),
                        songName(),
                        Row(
                          children: [
                            widget.isCompact
                                ? Container()
                                : SizedBox(
                                    height: 10,
                                  ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child:
                                  widget.playBtnPosition == PlayBtnPosition.left
                                      ? playPauseBtn()
                                      : Container(),
                            ),
                            Expanded(flex: 9, child: seekBar()),
                          ],
                        ),
                        widget.isCompact
                            ? Container()
                            : SizedBox(
                                height: 10,
                              ),
                        widget.playBtnPosition == PlayBtnPosition.bottom
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  (widget.melodyList[audioServiceIndex]
                                              ?.isSong ??
                                          false)
                                      ? favouriteBtn()
                                      : Container(),
                                  widget.melodyList.length > 1
                                      ? previousBtn()
                                      : Container(),
                                  playPauseBtn(),
                                  widget.melodyList.length > 1
                                      ? nextBtn()
                                      : Container(),
                                  (!(widget.melodyList[audioServiceIndex]
                                                  ?.isSong ??
                                              true) &&
                                          widget.isRecordBtnVisible)
                                      ? SizedBox(
                                          width: 20,
                                        )
                                      : Container(),
                                  (!(widget.melodyList[audioServiceIndex]
                                                  ?.isSong ??
                                              true) &&
                                          widget.isRecordBtnVisible)
                                      ? InkWell(
                                          onTap: () =>
                                              AppUtil.executeFunctionIfLoggedIn(
                                                  context, () {
                                            if (!Constants.ongoingEncoding) {
                                              Navigator.of(context).pushNamed(
                                                  '/melody-page',
                                                  arguments: {
                                                    'melody': widget.melodyList[
                                                        audioServiceIndex],
                                                    'type': Types.AUDIO
                                                  });
                                            } else {
                                              AppUtil.showToast(language(
                                                  ar: 'من فضلك قم برفع الفيديو السابق أولا',
                                                  en: 'Please upload the previous video first'));
                                            }
                                          }),
                                          child: Container(
                                            height: widget.btnSize,
                                            width: widget.btnSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey.shade300,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black54,
                                                  spreadRadius: 2,
                                                  blurRadius: 4,
                                                  offset: Offset(0,
                                                      2), // changes position of shadow
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.mic,
                                              color: MyColors.primaryColor,
                                            ),
                                          ),
                                        )
                                      : Container(),
                                  (!(widget.melodyList[audioServiceIndex]
                                                  ?.isSong ??
                                              true) &&
                                          widget.isRecordBtnVisible)
                                      ? SizedBox(
                                          width: 20,
                                        )
                                      : Container(),
                                  (!(widget.melodyList[audioServiceIndex]
                                                  ?.isSong ??
                                              true) &&
                                          widget.isRecordBtnVisible)
                                      ? InkWell(
                                          onTap: () =>
                                              AppUtil.executeFunctionIfLoggedIn(
                                                  context, () {
                                            if (!Constants.ongoingEncoding) {
                                              Navigator.of(context).pushNamed(
                                                  '/melody-page',
                                                  arguments: {
                                                    'melody': widget.melodyList[
                                                        audioServiceIndex],
                                                    'type': Types.VIDEO
                                                  });
                                            } else {
                                              AppUtil.showToast(language(
                                                  ar: 'من فضلك قم برفع الفيديو السابق أولا',
                                                  en: 'Please upload the previous video first'));
                                            }
                                          }),
                                          child: Container(
                                            height: widget.btnSize,
                                            width: widget.btnSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey.shade300,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black54,
                                                  spreadRadius: 2,
                                                  blurRadius: 4,
                                                  offset: Offset(0,
                                                      2), // changes position of shadow
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.videocam,
                                              color: MyColors.primaryColor,
                                            ),
                                          ),
                                        )
                                      : Container(),
                                  Constants.currentRoute != '/downloads'
                                      ? downloadOrOptions()
                                      : Container()
                                ],
                              )
                            : Container(),
                        widget.playBtnPosition == PlayBtnPosition.bottom
                            ? SizedBox(height: 10)
                            : Container()
                      ],
                    )),
                  ),
                ),
              )
            : Container();
      },
    );
  }

  Widget songName() => StreamBuilder<QueueState>(
        stream: _queueStateStream,
        builder: (context, snapshot) {
          final queueState = snapshot.data;
          final queue = queueState?.queue ?? [];
          final mediaItem = queueState?.mediaItem;
          return (mediaItem?.title != null)
              ? Text(
                  mediaItem.title,
                  style: TextStyle(
                      color: MyColors.textLightColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                )
              : Container();
        },
      );
  Widget seekBar() => StreamBuilder<MediaState>(
        stream: _mediaStateStream,
        builder: (context, snapshot) {
          final mediaState = snapshot.data;
          return SeekBar(
            duration: mediaState?.mediaItem?.duration ?? Duration.zero,
            position: mediaState?.position ?? Duration.zero,
            onChangeEnd: (newPosition) {
              AudioService.seekTo(newPosition);
            },
          );
        },
      );
  Widget previousBtn() => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: StreamBuilder<QueueState>(
          stream: _queueStateStream,
          builder: (context, snapshot) {
            final queueState = snapshot.data;
            final queue = queueState?.queue ?? [];
            final mediaItem = queueState?.mediaItem;
            return (queue != null && queue.isNotEmpty)
                ? Container(
                    height: widget.btnSize,
                    width: widget.btnSize,
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
                    child: InkWell(
                      child: Icon(
                        Icons.skip_previous,
                        size: widget.btnSize - 5,
                        color: MyColors.primaryColor,
                      ),
                      onTap: mediaItem == queue.first
                          ? null
                          : AudioService.skipToPrevious,
                    ),
                  )
                : Container();
          },
        ),
      );
  Widget playPauseBtn() => StreamBuilder<bool>(
        stream: AudioService.playbackStateStream
            .map((state) => state.playing)
            .distinct(),
        builder: (context, snapshot) {
          final playing = snapshot.data ?? false;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (playing) pauseButton() else playButton(),
            ],
          );
        },
      );
  Widget nextBtn() => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: StreamBuilder<QueueState>(
          stream: _queueStateStream,
          builder: (context, snapshot) {
            final queueState = snapshot.data;
            final queue = queueState?.queue ?? [];
            final mediaItem = queueState?.mediaItem;
            return (queue != null && queue.isNotEmpty)
                ? Container(
                    height: widget.btnSize,
                    width: widget.btnSize,
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
                    child: InkWell(
                      child: Icon(
                        Icons.skip_next,
                        color: MyColors.primaryColor,
                        size: widget.btnSize - 5,
                      ),
                      onTap: mediaItem == queue.last
                          ? null
                          : AudioService.skipToNext,
                    ),
                  )
                : Container();
          },
        ),
      );
  bool _isFavourite = false;

  isFavourite() async {
    bool isFavourite = (await usersRef
            .doc(Constants.currentUserID)
            .collection('favourites')
            .doc(widget.melodyList[audioServiceIndex]?.id)
            .get())
        .exists;

    if (mounted) {
      setState(() {
        _isFavourite = isFavourite;
      });
    }
  }

  Widget favouriteBtn() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () async {
          _isFavourite
              ? await DatabaseService.deleteMelodyFromFavourites(
                  widget.melodyList[audioServiceIndex].id)
              : await DatabaseService.addMelodyToFavourites(
                  widget.melodyList[audioServiceIndex].id);

          await isFavourite();
        },
        child: Container(
          height: widget.btnSize,
          width: widget.btnSize,
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
            _isFavourite ? Icons.favorite : Icons.favorite_border,
            color: MyColors.primaryColor,
          ),
        ),
      ),
    );
  }

  List<String> choices;
  Widget downloadOrOptions() {
    return Constants.isAdmin ?? false
        ? Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(
              height: widget.btnSize,
              width: widget.btnSize,
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
              child: PopupMenuButton<String>(
                child: Icon(
                  Icons.more_vert,
                  color: MyColors.primaryColor,
                  size: widget.btnSize - 5,
                ),
                color: MyColors.accentColor,
                elevation: 0,
                onCanceled: () {
                  print('You have not chosen anything');
                },
                onSelected: _select,
                itemBuilder: (BuildContext context) {
                  return choices.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(
                        choice,
                        style: TextStyle(color: MyColors.primaryColor),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          )
        : widget.melodyList[audioServiceIndex]?.authorId != null ?? false
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: () async {
                    AppUtil.executeFunctionIfLoggedIn(context, () {
                      _downloadMelody();
                    });
                  },
                  child: Container(
                    height: widget.btnSize,
                    width: widget.btnSize,
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
                      Icons.file_download,
                      color: MyColors.primaryColor,
                      size: widget.btnSize - 10,
                    ),
                  ),
                ),
              )
            : Container();
  }

  void _select(String value) async {
    switch (value) {
      case Strings.en_edit_image:
        await editImage();
        break;
      case Strings.ar_edit_image:
        await editImage();
        break;

      case Strings.en_edit_name:
        await editName();
        break;
      case Strings.ar_edit_name:
        await editName();
        break;

      case Strings.en_delete:
        await deleteMelody();
        break;
      case Strings.ar_delete:
        await deleteMelody();
        break;

      case Strings.ar_edit_lyrics:
        Navigator.of(context).pushNamed('/lyrics-editor',
            arguments: {'melody': widget.melodyList[audioServiceIndex]});
        break;
      case Strings.ar_edit_lyrics:
        Navigator.of(context).pushNamed('/lyrics-editor',
            arguments: {'melody': widget.melodyList[audioServiceIndex]});
        break;
    }
  }

  editImage() async {
    File image = await AppUtil.pickImageFromGallery();
    String ext = path.extension(image.path);

    if (widget.melodyList[audioServiceIndex].imageUrl != null) {
      String fileName = await AppUtil.getStorageFileNameFromUrl(
          widget.melodyList[audioServiceIndex].imageUrl);
      await storageRef.child('/melodies_images/$fileName').delete();
    }

    String url = await AppUtil().uploadFile(image, context,
        '/melodies_images/${widget.melodyList[audioServiceIndex].id}$ext');
    await melodiesRef
        .doc(widget.melodyList[audioServiceIndex].id)
        .update({'image_url': url});
    AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
  }

  TextEditingController _nameController = TextEditingController();
  editName() async {
    setState(() {
      _nameController.text = widget.melodyList[audioServiceIndex].name;
    });
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
              controller: _nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(hintText: 'New name'),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) {
                AppUtil.showToast(
                    language(en: 'Please enter a name', ar: 'قم ادخال اسم'));
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              await melodiesRef
                  .doc(widget.melodyList[audioServiceIndex].id)
                  .update({
                'name': _nameController.text,
                'search': searchList(_nameController.text),
              });
              AppUtil.showToast(
                  language(en: Strings.en_updated, ar: Strings.ar_updated));
              Navigator.of(context).pop();
            },
            color: MyColors.primaryColor,
            child: Text(
              language(en: Strings.en_update, ar: Strings.ar_update),
              style: TextStyle(color: MyColors.textLightColor),
            ),
          )
        ],
      ),
    )));
  }

  deleteMelody() async {
    AppUtil.showAlertDialog(
        context: context,
        message: 'Are you sure you want to delete this melody?',
        firstBtnText: 'Yes',
        firstFunc: () async {
          Navigator.of(context).pop();
          AppUtil.showLoader(context);
          await DatabaseService.deleteMelody(
              widget.melodyList[audioServiceIndex]);
          Singer singer = await DatabaseService.getSingerWithName(
              widget.melodyList[audioServiceIndex].singer);
          if (widget.melodyList[audioServiceIndex].isSong) {
            await singersRef
                .doc(singer.id)
                .update({'songs': FieldValue.increment(-1)});
          } else {
            await singersRef
                .doc(singer.id)
                .update({'melodies': FieldValue.increment(-1)});
          }
          AppUtil.showToast(language(en: 'Deleted!', ar: 'تم الحذف'));
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        secondBtnText: 'No',
        secondFunc: () {
          Navigator.of(context).pop();
        });
  }

  bool isStoragePermissionGranted = false;
  createAppFolder() async {
    if (await PermissionsService().hasStoragePermission()) {
      setState(() {
        isStoragePermissionGranted = true;
      });
      print('storage permission granted');
    } else {
      bool isGranted = await PermissionsService()
          .requestStoragePermission(context, onPermissionDenied: () async {
        PermissionStatus status = await PermissionsService()
            .checkPermissionStatus(PermissionGroup.storage);

        if (status == PermissionStatus.neverAskAgain) {
          AppUtil.showAlertDialog(
              context: context,
              message: language(
                  en: 'You have chosen to never ask for this permission again, please go to settings and choose permissions to allow this.',
                  ar: 'لقد اخترت عدم طلب الإذن مرة أخرى، برجاء الذهاب للضبط وإعطاء الإذن'),
              firstBtnText: language(en: 'Go to settings', ar: 'الذهاب للضبط'),
              firstFunc: () {
                Navigator.of(context).pop();
                PermissionHandler().openAppSettings();
                return;
              },
              secondBtnText: language(en: 'Cancel', ar: 'إلغاء'),
              secondFunc: () {
                Navigator.of(context).pop();
              });
        } else if (status == PermissionStatus.denied)
          AppUtil.showAlertDialog(
            context: context,
            heading: 'info',
            message: language(
                en: 'You must grant this microphone access to be able to use this feature.',
                ar: 'من فضلك قم بالسماح باستخدام الميكروفون من أجل استخدام هذه الخاصية'),
            firstBtnText: language(en: 'Give Permission', ar: 'السماح'),
            firstFunc: () async {
              Navigator.of(context).pop(false);
              await createAppFolder();
            },
            secondBtnText: language(en: 'Leave', ar: 'خروج'),
            secondFunc: () async {
              print('storage permission denied');
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );

        print('storage permission denied');
      });
      setState(() {
        isStoragePermissionGranted = isGranted;
      });
      return;
    }

    if (isStoragePermissionGranted) {
      print('deleting temp files then creating an empty folder...');
      await AppUtil.deleteFiles();
      await AppUtil.createAppDirectory();
    }
  }

  void _downloadMelody() async {
    Token token = Token();
    if (widget.melodyList[audioServiceIndex].price == null ||
        widget.melodyList[audioServiceIndex].price == '0') {
      token.tokenId = 'free';
    } else {
      DocumentSnapshot doc = await usersRef
          .doc(Constants.currentUserID)
          .collection('downloads')
          .doc(widget.melodyList[audioServiceIndex].id)
          .get();
      bool alreadyDownloaded = doc.exists;
      print('alreadyDownloaded: $alreadyDownloaded');

      if (!alreadyDownloaded) {
        final success = await Navigator.of(context).pushNamed('/payment-home',
            arguments: {'amount': widget.melodyList[audioServiceIndex].price});
        if (success) {
          usersRef
              .doc(Constants.currentUserID)
              .collection('downloads')
              .doc(widget.melodyList[audioServiceIndex].id)
              .set({'timestamp': FieldValue.serverTimestamp()});
        }
        token.tokenId = 'purchased';

        print(token.tokenId);
      } else {
        token.tokenId = 'already purchased';
        AppUtil.showToast(language(en: 'already purchased', ar: 'تم الشراء'));
      }
    }
    if (token.tokenId != null) {
      AppUtil.showLoader(context);
      await createAppFolder();
      String path;
      if (widget.melodyList[audioServiceIndex].audioUrl != null) {
        path = await AppUtil.downloadFile(
            widget.melodyList[audioServiceIndex].audioUrl,
            encrypt: true);
      } else {
        path = await AppUtil.downloadFile(
            widget.melodyList[audioServiceIndex].levelUrls.values.elementAt(0),
            encrypt: true);
      }

      Melody melody = Melody(
          id: widget.melodyList[audioServiceIndex].id,
          authorId: widget.melodyList[audioServiceIndex].authorId,
          duration: widget.melodyList[audioServiceIndex].duration,
          imageUrl: widget.melodyList[audioServiceIndex].imageUrl,
          name: widget.melodyList[audioServiceIndex].name,
          audioUrl: path);
      Melody storedMelody = await MelodySqlite.getMelodyWithId(
          widget.melodyList[audioServiceIndex].id);
      if (storedMelody == null) {
        await MelodySqlite.insert(melody);
        await usersRef
            .doc(Constants.currentUserID)
            .collection('downloads')
            .doc(widget.melodyList[audioServiceIndex].id)
            .set({'timestamp': FieldValue.serverTimestamp()});
        Navigator.of(context).pop();
        AppUtil.showToast(language(en: 'Downloaded!', ar: 'تم التحميل'));
        Navigator.of(context).pushNamed('/downloads');
      } else {
        Navigator.of(context).pop();
        AppUtil.showToast('Already downloaded!');
        Navigator.of(context).pushNamed('/downloads');
      }
    }
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem, Duration, MediaState>(
          AudioService.currentMediaItemStream,
          AudioService.positionStream,
          (mediaItem, position) => MediaState(mediaItem, position));

  /// A stream reporting the combined state of the current queue and the current
  /// media item within that queue.
  Stream<QueueState> get _queueStateStream =>
      Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
          AudioService.queueStream,
          AudioService.currentMediaItemStream,
          (queue, mediaItem) => QueueState(queue, mediaItem));

  RaisedButton audioPlayerButton() => startButton(
        'AudioPlayer',
        () {
          AudioService.start(
            backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
            androidNotificationChannelName: 'Audio Service Demo',
            // Enable this if you want the Android service to exit the foreground state on pause.
            //androidStopForegroundOnPause: true,
            androidNotificationColor: 0xFF2196f3,
            androidNotificationIcon: 'mipmap/ic_launcher',
            androidEnableQueue: true,
          );
        },
      );

  RaisedButton startButton(String label, VoidCallback onPressed) =>
      RaisedButton(
        child: Text(label),
        onPressed: onPressed,
      );

  Widget playButton() => InkWell(
        onTap: () => AudioService.play(),
        child: Container(
          height: widget.btnSize,
          width: widget.btnSize,
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
            size: widget.btnSize - 5,
            color: MyColors.primaryColor,
          ),
        ),
      );

  Widget pauseButton() => InkWell(
        onTap: () => AudioService.pause(),
        child: Container(
          height: widget.btnSize,
          width: widget.btnSize,
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
            Icons.pause,
            size: widget.btnSize - 5,
            color: MyColors.primaryColor,
          ),
        ),
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: 64.0,
        onPressed: AudioService.stop,
      );
}

int audioServiceIndex = 0;

class QueueState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;

  QueueState(this.queue, this.mediaItem);
}

class MediaState {
  final MediaItem mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;

  SeekBar({
    @required this.duration,
    @required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final value = min(_dragValue ?? widget.position?.inMilliseconds?.toDouble(),
        widget.duration.inMilliseconds.toDouble());
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    return Stack(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5.0,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            activeColor: MyColors.darkPrimaryColor,
            inactiveColor: Colors.grey.shade300,
            min: 0.0,
            max: widget.duration.inMilliseconds.toDouble(),
            value: value,
            onChanged: (value) {
              if (!_dragging) {
                _dragging = true;
              }
              setState(() {
                _dragValue = value;
              });
              if (widget.onChanged != null) {
                widget.onChanged(Duration(milliseconds: value.round()));
              }
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd(Duration(milliseconds: value.round()));
              }
              _dragging = false;
            },
          ),
        ),
        Positioned(
          right: 16.0,
          bottom: -2.0,
          child: Text(
            RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                    .firstMatch("$_remaining")
                    ?.group(1) ??
                '$_remaining',
            style: TextStyle(
              fontSize: 12,
              color: MyColors.textLightColor,
            ),
          ),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}

// NOTE: Your entrypoint MUST be a top-level function.
void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class MediaLibrary {
  List<MediaItem> _items = [];
  MediaLibrary(List<Melody> melodyList, {MediaLibrary oldOne}) {
    if (oldOne != null) {
      _items.addAll(oldOne.items);
    }
    melodyList.forEach((element) {
      _items.add(MediaItem(
          id: element.audioUrl,
          album: element.singer,
          title: element.name,
          artist: element.singer,
          duration: Duration(seconds: element.duration),
          artUri:
              element.imageUrl ?? 'asset:///${Strings.default_melody_image}'));
    });
  }

  List<MediaItem> get items => _items;
}

/// This task defines logic for playing a list of podcast episodes.
class AudioPlayerTask extends BackgroundAudioTask {
  MediaLibrary _mediaLibrary;
  AudioPlayer _player = new AudioPlayer();
  AudioProcessingState _skipState;
  Seeker _seeker;
  StreamSubscription<PlaybackEvent> _eventSubscription;

  List<MediaItem> get queue => _mediaLibrary.items;
  int get index => _player.currentIndex;
  MediaItem get mediaItem => index == null ? null : queue[index];

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // We configure the audio session for speech since we're playing a podcast.
    // You can also put this in your app's initialisation if your app doesn't
    // switch between two types of audio as this example does.
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    //if (queue.length == 0) return;

    // Broadcast media item changes.
    _player.currentIndexStream.listen((index) {
      if (index != null) AudioServiceBackground.setMediaItem(queue[index]);
      audioServiceIndex = index;
    });
    // Propagate all events from the audio player to AudioService clients.
    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });
    // Special processing for state transitions.
    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // In this example, the service stops when reaching the end.
          onStop();
          break;
        case ProcessingState.ready:
          // If we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          _skipState = null;
          break;
        default:
          break;
      }
    });

    if (queue.length != 0) {
      // Load and broadcast the queue
      AudioServiceBackground.setQueue(queue);
      try {
        await _player.setAudioSource(ConcatenatingAudioSource(
          children: queue
              .map((item) =>
                  AudioSource.uri(Uri.parse(item.id.replaceAll(' ', '%20'))))
              .toList(),
        ));

        /// In this example, we automatically start playing on start.
        onPlay();
      } catch (e) {
        print("Audio Source Error: $e");
        onStop();
      }
    }
  }

  @override
  Future<dynamic> onCustomAction(String name, dynamic arguments) {
    switch (name) {
      case 'addMediaSources':
        Map<String, dynamic> decoded = jsonDecode(arguments);

        Melody melody = Melody.fromMap(decoded);
        _mediaLibrary = MediaLibrary([melody],
            oldOne: _mediaLibrary != null ? _mediaLibrary : null);
        // Load and broadcast the queue
        AudioServiceBackground.setQueue(queue);
        try {
          print('Local File:${queue[0].id}');
          _player.setAudioSource(ConcatenatingAudioSource(
            children: queue
                .map((item) =>
                    AudioSource.uri(Uri.parse(item.id.replaceAll(' ', '%20'))))
                .toList(),
          ));
        } catch (e) {
          print("Audio Source Error:: $e");
          onStop();
        }
        break;
      case 'clearMediaLibrary':
        _mediaLibrary = null;
        break;
    }
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    // Then default implementations of onSkipToNext and onSkipToPrevious will
    // delegate to this method.
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return;
    // During a skip, the player may enter the buffering state. We could just
    // propagate that state directly to AudioService clients but AudioService
    // has some more specific states we could use for skipping to next and
    // previous. This variable holds the preferred state to send instead of
    // buffering during a skip, and it is cleared as soon as the player exits
    // buffering (see the listener in onStart).
    _skipState = newIndex > index
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    // This jumps to the beginning of the queue item at newIndex.
    _player.seek(Duration.zero, index: newIndex);
    // Demonstrate custom events.
    AudioServiceBackground.sendCustomEvent('skip to $newIndex');
  }

  @override
  Future<void> onPlay() => _player.play();

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration position) => _player.seek(position);

  @override
  Future<void> onFastForward() => _seekRelative(fastForwardInterval);

  @override
  Future<void> onRewind() => _seekRelative(-rewindInterval);

  @override
  Future<void> onSeekForward(bool begin) async => _seekContinuously(begin, 1);

  @override
  Future<void> onSeekBackward(bool begin) async => _seekContinuously(begin, -1);

  @override
  Future<void> onStop() async {
    await _player.dispose();
    _eventSubscription.cancel();
    // It is important to wait for this state to be broadcast before we shut
    // down the task. If we don't, the background task will be destroyed before
    // the message gets sent to the UI.
    await _broadcastState();
    // Shut down this task
    await super.onStop();
  }

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _player.position + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
    // Perform the jump via a seek.
    await _player.seek(newPosition);
  }

  /// Begins or stops a continuous seek in [direction]. After it begins it will
  /// continue seeking forward or backward by 10 seconds within the audio, at
  /// intervals of 1 second in app time.
  void _seekContinuously(bool begin, int direction) {
    _seeker?.stop();
    if (begin) {
      _seeker = Seeker(_player, Duration(seconds: 10 * direction),
          Duration(seconds: 1), mediaItem)
        ..start();
    }
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    if (_skipState != null) return _skipState;
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }
}

/// Provides access to a library of media items. In your app, this could come
/// from a database or web service.
//List<Melody> melodyListx
// = [
//   // Melody(
//   //     audioUrl:
//   //         'https://firebasestorage.googleapis.com/v0/b/dubsmash-75a05.appspot.com/o/songs%2FtBZw7Aseel%20Hamem%20%26%20Hussin%20Ghazal%20-%20ady.wav?alt=media&token=76bde1cd-a1a3-4758-9edc-cdb229fd179d',
//   //     imageUrl:
//   //         'https://firebasestorage.googleapis.com/v0/b/dubsmash-75a05.appspot.com/o/melodies_images%2FbsXuSAseel%20%26%20Hussin%20.jpg?alt=media&token=50662df3-f6ac-489d-a13d-28fe905c3c04',
//   //     singer: 'اصيل ‏هميم ‏و ‏حسين ‏الغزال',
//   //     name: 'عادي',
//   //     duration: 165,
//   //     isSong: true),
//   // Melody(
//   //     audioUrl:
//   //         'https://firebasestorage.googleapis.com/v0/b/dubsmash-75a05.appspot.com/o/songs%2FOoP1o_Aseel%20Hameem%20%26%20NASRAT%20ALBADER-Ale%20Ghumarny.wav?alt=media&token=f364dcc4-1db0-43f5-8380-f86a99ad6f08',
//   //     imageUrl:
//   //         'https://firebasestorage.googleapis.com/v0/b/dubsmash-75a05.appspot.com/o/melodies_images%2FMdGwVNasrat%20-%20Aseel.jpg?alt=media&token=c04f8007-4f4f-4c5c-a4e6-694da2e7849a',
//   //     singer: 'اصيل ‏هميم ‏و ‏نصرت ‏البدر',
//   //     name: 'الي غمرني',
//   //     duration: 223,
//   //     isSong: true),
// ];

/// Provides access to a library of media items. In your app, this could come
/// from a database or web service.

/// An object that performs interruptable sleep.
class Sleeper {
  Completer _blockingCompleter;

  /// Sleep for a duration. If sleep is interrupted, a
  /// [SleeperInterruptedException] will be thrown.
  Future<void> sleep([Duration duration]) async {
    _blockingCompleter = Completer();
    if (duration != null) {
      await Future.any([Future.delayed(duration), _blockingCompleter.future]);
    } else {
      await _blockingCompleter.future;
    }
    final interrupted = _blockingCompleter.isCompleted;
    _blockingCompleter = null;
    if (interrupted) {
      throw SleeperInterruptedException();
    }
  }

  /// Interrupt any sleep that's underway.
  void interrupt() {
    if (_blockingCompleter?.isCompleted == false) {
      _blockingCompleter.complete();
    }
  }
}

class SleeperInterruptedException {}

/// A wrapper around FlutterTts that makes it easier to wait for speech to
/// complete.
class Tts {
  final FlutterTts _flutterTts = new FlutterTts();
  Completer _speechCompleter;
  bool _interruptRequested = false;
  bool _playing = false;

  Tts() {
    _flutterTts.setCompletionHandler(() {
      _speechCompleter?.complete();
    });
  }

  bool get playing => _playing;

  Future<void> speak(String text) async {
    _playing = true;
    if (!_interruptRequested) {
      _speechCompleter = Completer();
      await _flutterTts.speak(text);
      await _speechCompleter.future;
      _speechCompleter = null;
    }
    _playing = false;
    if (_interruptRequested) {
      _interruptRequested = false;
      throw TtsInterruptedException();
    }
  }

  Future<void> stop() async {
    if (_playing) {
      await _flutterTts.stop();
      _speechCompleter?.complete();
    }
  }

  void interrupt() {
    if (_playing) {
      _interruptRequested = true;
      stop();
    }
  }
}

class TtsInterruptedException {}

class Seeker {
  final AudioPlayer player;
  final Duration positionInterval;
  final Duration stepInterval;
  final MediaItem mediaItem;
  bool _running = false;

  Seeker(
    this.player,
    this.positionInterval,
    this.stepInterval,
    this.mediaItem,
  );

  start() async {
    _running = true;
    while (_running) {
      Duration newPosition = player.position + positionInterval;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
      player.seek(newPosition);
      await Future.delayed(stepInterval);
    }
  }

  stop() {
    _running = false;
  }
}
