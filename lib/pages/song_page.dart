import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/pages/tracks_page.dart';
import 'package:Alhany/pages/upload_track.dart';
import 'package:Alhany/services/my_audio_player.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/local_music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_util.dart';
import 'melody_page.dart';

class SongPage extends StatefulWidget {
  final Melody song;

  const SongPage({Key key, this.song}) : super(key: key);
  @override
  _SongPageState createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  Future<bool> _onBackPressed() {
    Constants.currentRoute = '';
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: Constants.isAdmin
              ? Container(
                  width: 100.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: MyColors.accentColor),
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    color: MyColors.accentColor,
                  ),
                  child: new RawMaterialButton(
                    shape: new CircleBorder(),
                    elevation: 5.0,
                    child: Text(
                      'Add Track',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => UploadTrackPage(
                                  song: widget.song,
                                ))),
                  ))
              : null,
          body: Stack(
            children: [
              Container(
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
                      margin: 10,
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
                    SizedBox(
                      height: 25,
                    ),
                    ChangeNotifierProvider(
                      create: (context) => MyAudioPlayer(),
                      child: LocalMusicPlayer(
                        btnSize: 35,
                        isCompact: true,
                        onBuy: () => Melody.buySong(context, widget.song),
                        playBtnPosition: PlayBtnPosition.left,
                        initialDuration: widget.song.duration,
                        melodyList: [widget.song],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width / 4,
                    ),
                    widget.song.melodyUrl != null
                        ? InkWell(
                            onTap: () =>
                                AppUtil.executeFunctionIfLoggedIn(context, () {
                              if (!Constants.ongoingEncoding) {
                                Navigator.of(context).pushNamed('/melody-page',
                                    arguments: {
                                      'melody': widget.song,
                                      'type': Types.AUDIO
                                    });
                              } else {
                                AppUtil.showToast(language(
                                    ar: 'من فضلك قم برفع الفيديو السابق أولا',
                                    en: 'Please upload the previous video first'));
                              }
                            }),
                            child: Container(
                              height: MediaQuery.of(context).size.width / 6,
                              width: MediaQuery.of(context).size.width / 6,
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
                                size: MediaQuery.of(context).size.width / 8,
                              ),
                            ),
                          )
                        : Container(),
                    SizedBox(
                      height: MediaQuery.of(context).size.width / 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: MaterialButton(
                        padding: EdgeInsets.all(16),
                        minWidth: MediaQuery.of(context).size.width,
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => TracksPage(
                                      song: widget.song,
                                    ))),
                        child: Text(
                          '>>>  Tracks  <<<',
                          style: TextStyle(fontSize: 20),
                        ),
                        color: MyColors.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
