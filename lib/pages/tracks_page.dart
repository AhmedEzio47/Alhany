import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/track_model.dart';
import 'package:Alhany/provider/revenuecat.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:Alhany/services/permissions_service.dart';
import 'package:Alhany/services/purchase_api.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/local_music_player.dart';
import 'package:Alhany/widgets/paywall_widget.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  bool visible = true;
  Track selectedTrack;

  loadProgress() {
    if (visible == true) {
      setState(() {
        visible = false;
      });
    } else {
      setState(() {
        visible = true;
      });
    }
  }

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
            Visibility(
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                visible: visible,
                child: Container(
                    margin: EdgeInsets.only(top: 50, bottom: 30),
                    child: CircularProgressIndicator())),
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
                    RegularAppbar(
                      context,
                      color: Colors.black,
                      margin: 10,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.arrow_back,
                            color: MyColors.accentColor,
                          ),
                        ),
                      ),
                    ),
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
                            if (_tracks[index].duration != 0 &&
                                    _tracks[index].ownerId == null ||
                                _tracks[index].ownerId ==
                                    Constants.currentUserID) {
                              return ListTile(
                                onTap: () async {
                                  _index = index;
                                  setState(() {
                                    musicPlayer = ChangeNotifierProvider(
                                      create: (context) => MyAudioPlayer(),
                                      child: LocalMusicPlayer(
                                        showFavBtn: false,
                                        onDownload: () =>
                                            buyTrack(_tracks[index]),
                                        checkPrice: false,
                                        key: ValueKey(_tracks[index].id),
                                        melodyList: [
                                          Melody(
                                              price:
                                                  _tracks[index].price ?? '0',
                                              name: _tracks[index].name,
                                              duration: _tracks[index].duration,
                                              songUrl: _tracks[index].audio)
                                        ],
                                        backColor: MyColors.lightPrimaryColor,
                                        title: _tracks[index].name,
                                        initialDuration:
                                            _tracks[index].duration,
                                      ),
                                    );
                                    _isPlaying = true;
                                  });
                                },
                                tileColor: Colors.white.withOpacity(.5),
                                title: Text(
                                  _tracks[index].name,
                                  style:
                                      TextStyle(color: MyColors.textLightColor),
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
                                  style:
                                      TextStyle(color: MyColors.textLightColor),
                                ),
                              );
                            } else if (_tracks[index].duration == 0 &&
                                    _tracks[index].ownerId == null ||
                                _tracks[index].ownerId ==
                                    Constants.currentUserID) {
                              print('we are here!');
                              return ListTile(
                                onTap: () async {
                                  _index = index;
                                  bool _canUseThisTrack =
                                      await hasPurchasedThisTrack(
                                          _tracks[index]);
                                  if (!_canUseThisTrack) {
                                    buyTrack(_tracks[index]);
                                    return;
                                  }
                                },
                                tileColor: Colors.white.withOpacity(.5),
                                title: Text(
                                  _tracks[index].name,
                                  style:
                                      TextStyle(color: MyColors.textLightColor),
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
                                  style:
                                      TextStyle(color: MyColors.textLightColor),
                                ),
                              );
                            }
                            return Container();
                          }),
                    )
                  ],
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

  Future<bool> buyTrack(Track track) async {
    selectedTrack = track;
    await AppUtil.showAlertDialog(
        context: context,
        message: language(
            ar: 'هل تريد شراء هذا العرض ؟',
            en: 'Do you want to buy this offer?'),
        firstBtnText: language(ar: 'نعم', en: 'Yes'),
        secondBtnText: language(ar: 'لا', en: 'No'),
        firstFunc: () async {
          loadProgress();
          track.price == "14.99"
              ? fetchOffers(PurchaseTracks.oneTrackPurchaseID)
              : fetchOffers(PurchaseTracks.allTracksPurchaseID);
          //final success = await Navigator.of(context).pushNamed('/payment-home',
          //    arguments: {'amount': track.price});
        },
        secondFunc: () {
          Navigator.of(context).pop();
          return false;
        });

    return false;
  }

  Future downloadTrack() async {
    AppUtil.showLoader(context);
    await AppUtil.createAppDirectory();
    String path;

    if (selectedTrack.audio != null) {
      if (!(await PermissionsService().hasStoragePermission())) {
        await PermissionsService().requestStoragePermission(context);
      }
      await AppUtil.deleteFiles();
      await AppUtil.createAppDirectory();
      path = await AppUtil.downloadFile(selectedTrack.audio, toDownloads: true);
    }

    Melody melody = Melody(
        id: selectedTrack.id,
        duration: selectedTrack.duration,
        imageUrl: selectedTrack.image,
        name: selectedTrack.name,
        songUrl: path);

    Melody storedMelody = await MelodySqlite.getMelodyWithId(selectedTrack.id);

    if (storedMelody == null) {
      await MelodySqlite.insert(melody);

      await usersRef
          .doc(Constants.currentUserID)
          .collection('owned_tracks')
          .doc(selectedTrack.id)
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

  Future<bool> hasPurchasedThisTrack(Track track) async {
    if ((double.parse(track.price) ?? 0) == 0) {
      print('Price: ${track.price} ');
      return true; // This melody is FREE to use
    } else if ((Constants.currentUser?.boughtTracks ?? []).contains(track.id)) {
      return true; // User has already purchased this melody
    }
    return false;
  }

  validateInAppPurchase(Entitlement entitlement, Function showUI) {
    switch (entitlement) {
      case Entitlement.exclusives:
        showUI();
        return;
      case Entitlement.free:
      default:
        return AppUtil.showAlertDialog(
          context: context,
          firstFunc: fetchOffers,
          firstBtnText: language(ar: 'اشتراك', en: 'Subscribe'),
          message: language(
              ar: 'من فضلك قم بالاشتراك لكي تستمع للحصريات',
              en: 'Please subscribe in order to listen to exclusives'),
          secondBtnText: language(ar: 'إلغاء', en: 'Cancel'),
          secondFunc: () => Navigator.of(context).pop(),
        );
    }
  }

  Future fetchOffers(String offer) async {
    final offerings = await PurchaseApi.fetchOffersByIds([offer]);
    print('fetchOffers.offerings $offerings');
    if (offerings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(language(
            ar: 'هذا العنصر غير متوفر للشراء حالياً',
            en: 'The app currently has no offers')),
      ));
    } else {
      //final offer = offerings.first;
      //print('Offer: $offer');
      final packages = offerings
          .map((offer) => offer.availablePackages)
          .expand((pair) => pair)
          .toList();
      _settingModalBottomSheet(packages);
    }
  }

  void _settingModalBottomSheet(List packages) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return PaywallWidget(
            packages: packages,
            title: language(ar: '🌟 امتلك هذا التراك', en: '🌟 Own this track'),
            description: language(
                ar: 'احصل على حقوق ملكية استخدام هذا التراك',
                en: 'Use this track with no copyrights'),
            onClickedPackage: (package) async {
              final success = await PurchaseApi.purchasePackage(package);
              if (success) {
                //final provider = Provider.of<RevenueCatProvider>(context,listen: false);
                //provider.updateUI();
                //downloadTrack and enable listening
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
                    .doc(selectedTrack.id)
                    .update({'owner_id': Constants.currentUserID});

                await downloadTrack();
                loadProgress();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(language(
                      ar: 'تمت عملية الشراء بنجاح', en: 'Purchase success')),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(language(
                      ar: 'لم تتم عملية الشراء', en: 'Purchase Failed')),
                ));
              }
              Future.delayed(Duration(milliseconds: 1000), () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              });
            },
          );
        });
  }
}
