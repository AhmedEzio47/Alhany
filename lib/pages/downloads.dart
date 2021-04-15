import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/services/encryption_service.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
//import 'package:Alhany/widgets/local_music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:flutter/material.dart';

import '../widgets/music_player.dart';

class DownloadsPage extends StatefulWidget {
  @override
  _DownloadsPageState createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<Melody> _downloads = [];

  bool _isPlaying = false;

  List<String> _decryptedPaths = [];

  getDownloads() async {
    List<Melody> downloads = await MelodySqlite.getDownloads();
    setState(() {
      if (downloads != null) {
        _downloads = downloads;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getDownloads();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              setState(() {
                _isPlaying = true;
              });

              AppUtil.showLoader(context);
              AppUtil.showToast(language(
                  en: 'Decrypting, please wait!', ar: 'برجاء الانتظار'));
              await playAllSongs();
              Navigator.of(context).pop();
            },
            child: Icon(Icons.playlist_play),
          ),
          body: InkWell(
            onTap: () {
              setState(() {
                _isPlaying = false;
              });
            },
            child: Stack(
              children: [
                SingleChildScrollView(
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
                          height: 50,
                        ),
                        authStatus == AuthStatus.NOT_LOGGED_IN
                            ? Padding(
                                padding: EdgeInsets.only(
                                    top:
                                        MediaQuery.of(context).size.height / 2 -
                                            50),
                                child: Text(
                                  language(
                                      en: 'Please log in to see page content',
                                      ar: 'من فضلك قم بتسجيل الدخول لترى محتوى الصفحة'),
                                  style:
                                      TextStyle(color: MyColors.textLightColor),
                                ),
                              )
                            : _downloads.length > 0
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _downloads.length,
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () async {
                                          setState(() {
                                            _isPlaying = true;
                                          });

                                          AppUtil.showLoader(context);
                                          await playSong(index);
                                          Navigator.of(context).pop();
                                        },
                                        child: MelodyItem(
                                          //Solves confusion between songs and melodies when adding to favourites
                                          key: ValueKey('song_item'),
                                          melody: _downloads[index],
                                        ),
                                      );
                                    })
                                : Padding(
                                    padding: EdgeInsets.only(
                                        top:
                                            MediaQuery.of(context).size.height /
                                                    2 -
                                                40),
                                    child: Text(
                                      'No downloads yet!',
                                      style: TextStyle(
                                          color: MyColors.textLightColor,
                                          fontSize: 18),
                                    ),
                                  ),
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
        ),
      ),
    );
  }

  Future<bool> _onBack() async {
    for (String path in _decryptedPaths) {
      File file = File(path);
      await file.delete();
    }
    print('decrypted files deleted');
    setState(() {
      Constants.currentRoute = '';
    });
    Navigator.of(context).pop();
    return false;
  }

  playSong(int index) async {
    String path = EncryptionService.decryptFile(_downloads[index].audioUrl);
    if (!_decryptedPaths.contains(path)) {
      _decryptedPaths.add(path);
    }
    _downloads[index] = Melody(
        id: _downloads[index].id,
        isSong: _downloads[index].isSong,
        duration: _downloads[index].duration,
        name: _downloads[index].name,
        singer: _downloads[index].singer,
        audioUrl: path);

    musicPlayer = MusicPlayer(
      melodyList: [_downloads[index]],
      initialDuration: _downloads[index].duration,
      title: _downloads[index].name,
      isLocal: true,
      backColor: MyColors.lightPrimaryColor.withOpacity(.9),
    );
  }

  playAllSongs() {
    List<Melody> decryptedDownload = [];
    for (Melody song in _downloads) {
      String path = EncryptionService.decryptFile(song.audioUrl);
      if (!_decryptedPaths.contains(path)) {
        _decryptedPaths.add(path);
      }
      decryptedDownload.add(song.copyWith(audioUrl: path));
    }
    musicPlayer = MusicPlayer(
      melodyList: decryptedDownload,
      initialDuration: decryptedDownload[0].duration,
      isLocal: true,
      backColor: MyColors.lightPrimaryColor.withOpacity(.9),
    );
  }
}
