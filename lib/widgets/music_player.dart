import 'dart:async';
import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:audio_manager/audio_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:stripe_payment/stripe_payment.dart';

import 'custom_modal.dart';

typedef void OnError(Exception exception);

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
  _MusicPlayerState();

  // get isPlaying => AudioManager.instance.isPlaying == true;
  // get isPaused => AudioManager.instance.isPlaying == false;

  get durationText => AudioManager.instance.duration != null
      ? AudioManager.instance.duration.toString().split('.').first
      : '';

  get positionText => AudioManager.instance.position != null
      ? AudioManager.instance.position.toString().split('.').first
      : '';

  bool isMuted = false;
  List<String> choices;

  bool _isFavourite = false;

  int index = 0;

  isFavourite() async {
    bool isFavourite = (await usersRef
            .doc(Constants.currentUserID)
            .collection('favourites')
            .doc(widget.melodyList[index]?.id)
            .get())
        .exists;

    if (mounted) {
      setState(() {
        _isFavourite = isFavourite;
      });
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await isFavourite();
  }

  @override
  void initState() {
    super.initState();
    if (widget.melodyList[index]?.isSong ?? true) {
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
    initAudioPlayer();
  }

  @override
  void dispose() {
    AudioManager.instance.stop();
    AudioManager.instance.release();
    super.dispose();
  }

  Duration _duration;
  Duration _position;
  double _slider;
  bool isPlaying = AudioManager.instance.isPlaying ?? true;

  void initAudioPlayer() async {
    // List<String> urlList;
    // if (widget.melodyList != null) {
    //   urlList = [];
    //   for (Melody melody in widget.melodyList) {
    //     urlList.add(melody.audioUrl);
    //   }
    // }
    List<AudioInfo> _list = [];

    widget.melodyList.forEach((item) => _list.add(AudioInfo(item.audioUrl,
        title: item.name, desc: item.singer, coverUrl: item.imageUrl)));

    AudioManager.instance.audioList = _list;
    AudioManager.instance.intercepter = true;
    AudioManager.instance.play(auto: true);
    AudioManager.instance.onEvents((events, args) {
      print("$events, $args");
      switch (events) {
        case AudioManagerEvents.start:
          print(
              "start load data callback, curIndex is ${AudioManager.instance.curIndex}");
          _position = AudioManager.instance.position;
          _duration = AudioManager.instance.duration;
          _slider = 0;
          setState(() {});
          break;
        case AudioManagerEvents.ready:
          print("ready to play");
          // _error = null;
          // _sliderVolume = AudioManager.instance.volume;
          _position = AudioManager.instance.position;
          _duration = AudioManager.instance.duration;
          setState(() {});
          // if you need to seek times, must after AudioManagerEvents.ready event invoked
          // AudioManager.instance.seekTo(Duration(seconds: 10));
          break;
        case AudioManagerEvents.seekComplete:
          _position = AudioManager.instance.position;
          _slider = _position.inMilliseconds / _duration.inMilliseconds;
          setState(() {});
          print("seek event is completed. position is [$args]/ms");
          break;
        case AudioManagerEvents.buffering:
          print("buffering $args");
          break;
        case AudioManagerEvents.playstatus:
          isPlaying = AudioManager.instance.isPlaying;
          setState(() {});
          break;
        case AudioManagerEvents.timeupdate:
          _position = AudioManager.instance.position;
          _slider = _position.inMilliseconds / _duration.inMilliseconds;
          setState(() {});
          //AudioManager.instance.updateLrc(args["position"].toString());
          break;
        case AudioManagerEvents.error:
          //_error = args;
          print('Error: $args');
          setState(() {});
          break;
        case AudioManagerEvents.ended:
          next();
          break;
        case AudioManagerEvents.volumeChange:
          //_sliderVolume = AudioManager.instance.volume;
          setState(() {});
          break;
        default:
          break;
      }
    });
    // await AudioManager.instance
    //     .start(
    //         _list[index].url,
    //         // "network format resource"
    //         // "local resource (file://${file.path})"
    //         _list[index].title ?? '',
    //         desc: _list[index].desc ?? '',
    //         auto: true,
    //         cover: _list[index].coverUrl ?? '')
    //     .then((err) {
    //   print(err);
    // });
  }

  Future play() async {
    AudioManager.instance.playOrPause();
  }

  Future pause() async {
    await AudioManager.instance.playOrPause();
  }

  Future stop() async {
    await AudioManager.instance.stop();
  }

  NumberFormat _numberFormatter = new NumberFormat("##");

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(0),
        child: Padding(
          padding: EdgeInsets.all(widget.isCompact ? 8 : 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: new BorderRadius.circular(20.0),
              color: widget.backColor,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              widget.isCompact
                  ? Container()
                  : SizedBox(
                      height: 5,
                    ),
              widget.melodyList != null
                  ? Text(
                      widget.melodyList[index].name,
                      style: TextStyle(
                          color: MyColors.textLightColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    )
                  : widget.title != null
                      ? Text(
                          widget.title,
                          style: TextStyle(
                              color: MyColors.textLightColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        )
                      : Container(),
              Row(
                children: [
                  widget.isCompact
                      ? Container()
                      : SizedBox(
                          height: 10,
                        ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: widget.playBtnPosition == PlayBtnPosition.left
                        ? playPauseBtn()
                        : Container(),
                  ),
                  _position != null
                      ? Text(
                          '${_numberFormatter.format(_position.inMinutes)}:${_numberFormatter.format(_position.inSeconds % 60)}',
                          style: TextStyle(color: MyColors.textLightColor),
                        )
                      : Text(
                          '0:0',
                          style: TextStyle(color: MyColors.textLightColor),
                        ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 9,
                    child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5.0,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 16.0),
                        ),
                        child: Slider(
                          activeColor: MyColors.darkPrimaryColor,
                          inactiveColor: Colors.grey.shade300,
                          value: (_slider ?? double.infinity) >= 0 &&
                                      (_slider ?? double.infinity) <=
                                          _duration?.inMilliseconds ??
                                  double.maxFinite
                              ? _slider
                              : 0,
                          onChanged: (value) {
                            setState(() {
                              _slider = value;
                            });
                          },
                          onChangeEnd: (double value) {
                            if (_duration != null) {
                              Duration msec = Duration(
                                  milliseconds:
                                      (_duration.inMilliseconds * value)
                                          .round());
                              AudioManager.instance.seekTo(msec);
                            }

                            if (!isPlaying) {
                              play();
                            }
                          },
                        )),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  _duration != null
                      ? Text(
                          '${_numberFormatter.format(_duration?.inMinutes ?? 0)}:${_numberFormatter.format((_duration?.inSeconds ?? 0) % 60)}',
                          style: TextStyle(color: MyColors.textLightColor),
                        )
                      : Text(
                          '${_numberFormatter.format(widget.initialDuration ~/ 60)}:${_numberFormatter.format(widget.initialDuration % 60)}',
                          style: TextStyle(color: MyColors.textLightColor),
                        ),
                  SizedBox(
                    width: 10,
                  ),
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
                        (widget.melodyList[index]?.isSong ?? false)
                            ? favouriteBtn()
                            : Container(),
                        widget.melodyList.length > 1
                            ? previousBtn()
                            : Container(),
                        playPauseBtn(),
                        widget.melodyList.length > 1 ? nextBtn() : Container(),
                        (!(widget.melodyList[index]?.isSong ?? true) &&
                                widget.isRecordBtnVisible)
                            ? SizedBox(
                                width: 20,
                              )
                            : Container(),
                        (!(widget.melodyList[index]?.isSong ?? true) &&
                                widget.isRecordBtnVisible)
                            ? InkWell(
                                onTap: () => AppUtil.executeFunctionIfLoggedIn(
                                    context, () {
                                  Navigator.of(context).pushNamed(
                                    '/melody-page',
                                    arguments: {
                                      'melody': widget.melodyList[index],
                                      'type': Types.VIDEO
                                    },
                                  );
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
                                        offset: Offset(
                                            0, 2), // changes position of shadow
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
                        (!(widget.melodyList[index]?.isSong ?? true) &&
                                widget.isRecordBtnVisible)
                            ? SizedBox(
                                width: 20,
                              )
                            : Container(),
                        (!(widget.melodyList[index]?.isSong ?? true) &&
                                widget.isRecordBtnVisible)
                            ? InkWell(
                                onTap: () => AppUtil.executeFunctionIfLoggedIn(
                                    context, () {
                                  Navigator.of(context).pushNamed(
                                    '/melody-page',
                                    arguments: {
                                      'melody': widget.melodyList[index],
                                      'type': Types.VIDEO
                                    },
                                  );
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
                                        offset: Offset(
                                            0, 2), // changes position of shadow
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
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }

  Widget playPauseBtn() {
    return !isPlaying
        ? InkWell(
            onTap: () => isPlaying ? null : play(),
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
          )
        : InkWell(
            onTap: isPlaying ? () => pause() : null,
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
                color: MyColors.primaryColor,
                size: widget.btnSize - 5,
              ),
            ),
          );
  }

  Widget favouriteBtn() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => AppUtil.executeFunctionIfLoggedIn(context, () async {
          _isFavourite
              ? await DatabaseService.deleteMelodyFromFavourites(
                  widget.melodyList[index].id)
              : await DatabaseService.addMelodyToFavourites(
                  widget.melodyList[index].id);

          await isFavourite();
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
        : widget.melodyList[index]?.authorId != null ?? false
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: () async {
                    _downloadMelody();
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
            arguments: {'melody': widget.melodyList[index]});
        break;
      case Strings.ar_edit_lyrics:
        Navigator.of(context).pushNamed('/lyrics-editor',
            arguments: {'melody': widget.melodyList[index]});
        break;
    }
  }

  editImage() async {
    File image = await AppUtil.pickImageFromGallery();
    String ext = path.extension(image.path);

    if (widget.melodyList[index].imageUrl != null) {
      String fileName = await AppUtil.getStorageFileNameFromUrl(
          widget.melodyList[index].imageUrl);
      await storageRef.child('/melodies_images/$fileName').delete();
    }

    String url = await AppUtil().uploadFile(
        image, context, '/melodies_images/${widget.melodyList[index].id}$ext');
    await melodiesRef
        .doc(widget.melodyList[index].id)
        .update({'image_url': url});
    AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
  }

  TextEditingController _nameController = TextEditingController();
  editName() async {
    setState(() {
      _nameController.text = widget.melodyList[index].name;
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
              await melodiesRef.doc(widget.melodyList[index].id).update({
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
          await DatabaseService.deleteMelody(widget.melodyList[index]);
          Singer singer = await DatabaseService.getSingerWithName(
              widget.melodyList[index].singer);
          if (widget.melodyList[index].isSong) {
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

  void _downloadMelody() async {
    Token token = Token();
    if (widget.melodyList[index].price == null ||
        widget.melodyList[index].price == '0') {
      token.tokenId = 'free';
    } else {
      DocumentSnapshot doc = await usersRef
          .doc(Constants.currentUserID)
          .collection('downloads')
          .doc(widget.melodyList[index].id)
          .get();
      bool alreadyDownloaded = doc.exists;
      print('alreadyDownloaded: $alreadyDownloaded');

      if (!alreadyDownloaded) {
        final success = await Navigator.of(context).pushNamed('/payment-home',
            arguments: {'amount': widget.melodyList[index].price});
        if (success) {
          usersRef
              .doc(Constants.currentUserID)
              .collection('downloads')
              .doc(widget.melodyList[index].id)
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
      await AppUtil.createAppDirectory();
      String path;
      if (widget.melodyList[index].audioUrl != null) {
        path = await AppUtil.downloadFile(widget.melodyList[index].audioUrl,
            encrypt: true);
      } else {
        path = await AppUtil.downloadFile(
            widget.melodyList[index].levelUrls.values.elementAt(0),
            encrypt: true);
      }

      Melody melody = Melody(
          id: widget.melodyList[index].id,
          authorId: widget.melodyList[index].authorId,
          duration: widget.melodyList[index].duration,
          imageUrl: widget.melodyList[index].imageUrl,
          name: widget.melodyList[index].name,
          audioUrl: path);
      Melody storedMelody =
          await MelodySqlite.getMelodyWithId(widget.melodyList[index].id);
      if (storedMelody == null) {
        await MelodySqlite.insert(melody);
        await usersRef
            .doc(Constants.currentUserID)
            .collection('downloads')
            .doc(widget.melodyList[index].id)
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

  Widget nextBtn() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: InkWell(
        onTap: () => next(),
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
            Icons.skip_next,
            size: widget.btnSize - 5,
            color: MyColors.primaryColor,
          ),
        ),
      ),
    );
  }

  next() {
    if (this.index < widget.melodyList.length - 1)
      this.index++;
    else
      this.index = 0;
    AudioManager.instance.next();
  }

  previousBtn() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => previous(),
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
            Icons.skip_previous,
            size: widget.btnSize - 5,
            color: MyColors.primaryColor,
          ),
        ),
      ),
    );
  }

  previous() {
    if (this.index > 0)
      this.index--;
    else
      this.index = widget.melodyList.length - 1;
    AudioManager.instance.previous();
  }
}
