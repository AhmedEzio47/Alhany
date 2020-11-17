import 'dart:async';
import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:Alhany/services/payment_service.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:audioplayers/audioplayers.dart';
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
  final String url;
  final List<Melody> melodyList;
  final Color backColor;
  final Function onComplete;
  final bool isLocal;
  final String title;
  final double btnSize;
  final int initialDuration;
  final PlayBtnPosition playBtnPosition;
  final bool isCompact;

  final Melody melody;

  MusicPlayer(
      {Key key,
      this.url,
      this.backColor,
      this.onComplete,
      this.isLocal = false,
      this.title,
      this.btnSize = 40.0,
      this.initialDuration,
      this.melody,
      this.playBtnPosition = PlayBtnPosition.bottom,
      this.isCompact = false,
      this.melodyList})
      : super(key: key);

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  _MusicPlayerState();

  MyAudioPlayer myAudioPlayer;

  get isPlaying => myAudioPlayer.playerState == AudioPlayerState.PLAYING;
  get isPaused => myAudioPlayer.playerState == AudioPlayerState.PAUSED;

  get durationText => myAudioPlayer.duration != null ? myAudioPlayer.duration.toString().split('.').first : '';

  get positionText => myAudioPlayer.position != null ? myAudioPlayer.position.toString().split('.').first : '';

  bool isMuted = false;
  List<String> choices;

  bool _isFavourite = false;

  isFavourite() async {
    bool isFavourite =
        (await usersRef.document(Constants.currentUserID).collection('favourites').document(widget.melody?.id).get())
            .exists;

    setState(() {
      _isFavourite = isFavourite;
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await isFavourite();
  }

  @override
  void initState() {
    if (widget.melody?.isSong ?? true) {
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
    initAudioPlayer();
  }

  @override
  void dispose() {
    myAudioPlayer.stop();
    super.dispose();
  }

  Duration _duration;

  void initAudioPlayer() async {
    List<String> urlList;
    if (widget.melodyList != null) {
      urlList = [];
      for (Melody melody in widget.melodyList) {
        urlList.add(melody.audioUrl);
      }
    }
    myAudioPlayer =
        MyAudioPlayer(url: widget.url, urlList: urlList, isLocal: widget.isLocal, onComplete: widget.onComplete);
    myAudioPlayer.addListener(() {
      if (mounted) {
        setState(() {
          _duration = myAudioPlayer.duration;
        });
      }
    });
  }

  Future play() async {
    myAudioPlayer.play();
  }

  Future pause() async {
    await myAudioPlayer.pause();
  }

  Future stop() async {
    await myAudioPlayer.stop();
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
                      widget.melodyList[myAudioPlayer.index].name,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  : widget.title != null
                      ? Text(
                          widget.title,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                    child: widget.playBtnPosition == PlayBtnPosition.left ? playPauseBtn() : Container(),
                  ),
                  myAudioPlayer.position != null
                      ? Text(
                          '${_numberFormatter.format(myAudioPlayer.position.inMinutes)}:${_numberFormatter.format(myAudioPlayer.position.inSeconds % 60)}',
                          style: TextStyle(color: Colors.white),
                        )
                      : Text(
                          '0:0',
                          style: TextStyle(color: Colors.white),
                        ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 9,
                    child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5.0,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 16.0),
                        ),
                        child: Slider(
                            activeColor: MyColors.darkPrimaryColor,
                            inactiveColor: Colors.grey.shade300,
                            value: myAudioPlayer.position?.inMilliseconds?.toDouble() ?? 0.0,
                            onChanged: (double value) {
                              myAudioPlayer.seek(Duration(seconds: value ~/ 1000));

                              if (!isPlaying) {
                                play();
                              }
                            },
                            min: 0.0,
                            max: _duration != null ? _duration?.inMilliseconds?.toDouble() : 1.7976931348623157e+308)),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  myAudioPlayer.duration != null
                      ? Text(
                          '${_numberFormatter.format(_duration.inMinutes)}:${_numberFormatter.format(_duration.inSeconds % 60)}',
                          style: TextStyle(color: Colors.white),
                        )
                      : Text(
                          '${_numberFormatter.format(widget.initialDuration ~/ 60)}:${_numberFormatter.format(widget.initialDuration % 60)}',
                          style: TextStyle(color: Colors.white),
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
                        (widget.melody?.isSong ?? false) ? favouriteBtn() : Container(),
                        widget.melodyList != null ? previousBtn() : Container(),
                        playPauseBtn(),
                        widget.melodyList != null ? nextBtn() : Container(),
                        (!(widget.melody?.isSong ?? true))
                            ? SizedBox(
                                width: 20,
                              )
                            : Container(),
                        (!(widget.melody?.isSong ?? true))
                            ? InkWell(
                                onTap: () => Navigator.of(context).pushNamed('/melody-page',
                                    arguments: {'melody': widget.melody, 'type': Types.AUDIO}),
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
                                    Icons.mic,
                                    color: MyColors.primaryColor,
                                  ),
                                ),
                              )
                            : Container(),
                        (!(widget.melody?.isSong ?? true))
                            ? SizedBox(
                                width: 20,
                              )
                            : Container(),
                        (!(widget.melody?.isSong ?? true))
                            ? InkWell(
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/melody-page',
                                  arguments: {'melody': widget.melody, 'type': Types.VIDEO},
                                ),
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
                                    Icons.videocam,
                                    color: MyColors.primaryColor,
                                  ),
                                ),
                              )
                            : Container(),
                        Constants.currentRoute != '/downloads' ? downloadOrOptions() : Container()
                      ],
                    )
                  : Container(),
              widget.playBtnPosition == PlayBtnPosition.bottom ? SizedBox(height: 10) : Container()
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
        onTap: () async {
          _isFavourite
              ? await DatabaseService.deleteMelodyFromFavourites(widget.melody.id)
              : await DatabaseService.addMelodyToFavourites(widget.melody.id);

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
            color: MyColors.accentColor,
          ),
        ),
      ),
    );
  }

  Widget downloadOrOptions() {
    return Constants.isAdmin
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
                tooltip: 'This is tooltip',
                onSelected: _select,
                itemBuilder: (BuildContext context) {
                  return choices.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(
                        choice,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          )
        : widget.melody.isSong ?? true
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
                      color: MyColors.accentColor,
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
        Navigator.of(context).pushNamed('/lyrics-editor', arguments: {'melody': widget.melody});
        break;
      case Strings.ar_edit_lyrics:
        Navigator.of(context).pushNamed('/lyrics-editor', arguments: {'melody': widget.melody});
        break;
    }
  }

  editImage() async {
    File image = await AppUtil.pickImageFromGallery();
    String ext = path.extension(image.path);

    if (widget.melody.imageUrl != null) {
      String fileName = await AppUtil.getStorageFileNameFromUrl(widget.melody.imageUrl);
      await storageRef.child('/melodies_images/$fileName').delete();
    }

    String url = await AppUtil().uploadFile(image, context, '/melodies_images/${widget.melody.id}$ext');
    await melodiesRef.document(widget.melody.id).updateData({'image_url': url});
    AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
  }

  TextEditingController _nameController = TextEditingController();
  editName() async {
    setState(() {
      _nameController.text = widget.melody.name;
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
                AppUtil.showToast('Please enter a name');
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              await melodiesRef.document(widget.melody.id).updateData({
                'name': _nameController.text,
                'search': searchList(_nameController.text),
              });
              AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
              Navigator.of(context).pop();
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

  deleteMelody() async {
    AppUtil.showAlertDialog(
        context: context,
        message: 'Are you sure you want to delete this melody?',
        firstBtnText: 'Yes',
        firstFunc: () async {
          Navigator.of(context).pop();
          AppUtil.showLoader(context);
          await DatabaseService.deleteMelody(widget.melody);
          AppUtil.showToast('Deleted!');
          Navigator.of(context).pop();
        },
        secondBtnText: 'No',
        secondFunc: () {
          Navigator.of(context).pop();
        });
  }

  void _downloadMelody() async {
    Token token = Token();
    if (widget.melody.price == null || widget.melody.price == '0') {
      token.tokenId = 'free';
    } else {
      DocumentSnapshot doc =
          await usersRef.document(Constants.currentUserID).collection('downloads').document(widget.melody.id).get();
      bool alreadyDownloaded = doc.exists;
      print('alreadyDownloaded: $alreadyDownloaded');

      if (!alreadyDownloaded) {
        //Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen()));
        PaymentService.configureStripePayment();
        PaymentMethod paymentMethod = await PaymentService.createTokenWithCardForm();
        PaymentService.confirmPaymentIntent(paymentMethod, Strings.paymentSecret);

        print(token.tokenId);
      } else {
        token.tokenId = 'already purchased';
        AppUtil.showToast('already purchased');
      }
    }
    if (token.tokenId != null) {
      AppUtil.showLoader(context);
      await AppUtil.createAppDirectory();
      String path;
      if (widget.melody.audioUrl != null) {
        path = await AppUtil.downloadFile(widget.melody.audioUrl, encrypt: true);
      } else {
        path = await AppUtil.downloadFile(widget.melody.levelUrls.values.elementAt(0), encrypt: true);
      }

      Melody melody = Melody(
          id: widget.melody.id,
          authorId: widget.melody.authorId,
          duration: widget.melody.duration,
          imageUrl: widget.melody.imageUrl,
          name: widget.melody.name,
          audioUrl: path);
      Melody storedMelody = await MelodySqlite.getMelodyWithId(widget.melody.id);
      if (storedMelody == null) {
        await MelodySqlite.insert(melody);
        await usersRef
            .document(Constants.currentUserID)
            .collection('downloads')
            .document(widget.melody.id)
            .setData({'timestamp': FieldValue.serverTimestamp()});
        Navigator.of(context).pop();
        AppUtil.showToast('Downloaded!');
      } else {
        Navigator.of(context).pop();
        AppUtil.showToast('Already downloaded!');
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
    myAudioPlayer.next();
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
    myAudioPlayer.prev();
  }
}
