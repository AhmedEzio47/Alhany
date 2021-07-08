import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/track_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';

import '../app_util.dart';

class TracksPage extends StatefulWidget {
  final Melody song;

  const TracksPage({Key key, this.song}) : super(key: key);
  @override
  _TracksPageState createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  List<Track> _tracks = [];
  int _index = 0;
  bool _isPlaying = false;
  getTracks() async {
    List<Track> tracks = await DatabaseService.getTracks(widget.song.id);
    setState(() {
      _tracks = tracks;
    });
  }

  @override
  void initState() {
    super.initState();
    getTracks();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPlaying = false;
                });
              },
              child: Container(
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
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      child: Stack(
                        children: [
                          CachedImage(
                            height: 200,
                            width: MediaQuery.of(context).size.width,
                            defaultAssetImage: Strings.default_cover_image,
                            imageUrl: widget.song.imageUrl,
                            imageShape: BoxShape.rectangle,
                            assetFit: BoxFit.fill,
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 16),
                                  color: Colors.black.withOpacity(.6),
                                  child: Text(
                                    widget.song.name,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: _tracks.length,
                          itemBuilder: (context, index) {
                            return _tracks[index].ownerId == null ||
                                    _tracks[index].ownerId ==
                                        Constants.currentUserID
                                ? ListTile(
                                    onTap: () async {
                                      _index = index;
                                      setState(() {
                                        musicPlayer = MusicPlayer(
                                          showFavBtn: false,
                                          onDownload: downloadTrack,
                                          checkPrice: false,
                                          key: ValueKey(_tracks[index].id),
                                          melodyList: [
                                            Melody(
                                                price:
                                                    _tracks[index].price ?? '0',
                                                name: _tracks[index].name,
                                                duration:
                                                    _tracks[index].duration,
                                                songUrl: _tracks[index].audio)
                                          ],
                                          backColor: MyColors.lightPrimaryColor,
                                          title: _tracks[index].name,
                                          initialDuration:
                                              _tracks[index].duration,
                                        );
                                        _isPlaying = true;
                                      });
                                    },
                                    tileColor: Colors.white.withOpacity(.5),
                                    title: Text(
                                      _tracks[index].name,
                                      style: TextStyle(
                                          color: MyColors.textLightColor),
                                    ),
                                    leading: CachedImage(
                                      height: 50,
                                      width: 50,
                                      imageShape: BoxShape.rectangle,
                                      imageUrl: _tracks[index].image,
                                      defaultAssetImage:
                                          Strings.default_melody_image,
                                    ),
                                    trailing: Text(
                                      '${_tracks[index].price} \$',
                                      style: TextStyle(
                                          color: MyColors.textLightColor),
                                    ),
                                  )
                                : Container();
                          }),
                    )
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: RegularAppbar(
                  context,
                  color: Colors.black,
                  margin: 10,
                ),
              ),
            ),
            _isPlaying
                ? Positioned.fill(
                    child: Align(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: musicPlayer,
                    ),
                    alignment: Alignment.bottomCenter,
                  ))
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<bool> buyTrack() async {
    await AppUtil.showAlertDialog(
        context: context,
        message: language(
            ar: 'هل تريد شراء هذه الأغنية',
            en: 'Do you want to buy this song?'),
        firstBtnText: language(ar: 'نعم', en: 'Yes'),
        secondBtnText: language(ar: 'لا', en: 'No'),
        firstFunc: () async {
          final success = await Navigator.of(context).pushNamed('/payment-home',
              arguments: {'amount': widget.song.price});
          if (success) {
            await melodiesRef
                .doc(widget.song.id)
                .collection('tracks')
                .doc(_tracks[_index].id)
                .update({'owner_id': Constants.currentUserID});

            Navigator.of(context).pop();
            return true;
          }
        },
        secondFunc: () {
          Navigator.of(context).pop();
          return false;
        });

    return false;
  }

  Future downloadTrack() async {
    Token token = Token();

    if (_tracks[_index].price == null ||
        double.parse(_tracks[_index].price) == 0) {
      token.tokenId = 'free';
    } else {
      bool alreadyDownloaded =
          (_tracks[_index].ownerId == Constants.currentUserID);
      print('alreadyDownloaded: $alreadyDownloaded');

      if (!alreadyDownloaded) {
        final success = await Navigator.of(context).pushNamed('/payment-home',
            arguments: {'amount': _tracks[_index].price});
        if (success) {
          await usersRef
              .doc(Constants.currentUserID)
              .collection('owned_tracks')
              .doc(_tracks[_index].id)
              .set({
            'timestamp': FieldValue.serverTimestamp(),
            'song_id': widget.song.id
          });

          await melodiesRef
              .doc(widget.song.id)
              .collection('tracks')
              .doc(_tracks[_index].id)
              .update({'owner_id': Constants.currentUserID});

          token.tokenId = 'purchased';
          print(token.tokenId);
        }
      } else {
        token.tokenId = 'already purchased';
        AppUtil.showToast(language(en: 'already purchased', ar: 'تم الشراء'));
      }
    }
    if (token.tokenId != null) {
      AppUtil.showLoader(context);
      await AppUtil.createAppDirectory();
      String path;

      if (_tracks[_index].audio != null) {
        path = await AppUtil.downloadFile(
          _tracks[_index].audio,
        );
      }

      Melody melody = Melody(
          id: _tracks[_index].id,
          duration: _tracks[_index].duration,
          imageUrl: _tracks[_index].image,
          name: _tracks[_index].name,
          songUrl: path);

      Melody storedMelody =
          await MelodySqlite.getMelodyWithId(_tracks[_index].id);

      if (storedMelody == null) {
        await MelodySqlite.insert(melody);

        await usersRef
            .doc(Constants.currentUserID)
            .collection('owned_tracks')
            .doc(_tracks[_index].id)
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
}
