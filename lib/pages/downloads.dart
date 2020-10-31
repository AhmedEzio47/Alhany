import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/services/encryption_service.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:flutter/material.dart';

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
      child: Scaffold(
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
                      colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                      image: AssetImage(Strings.default_bg),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: _downloads.length > 0
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: _downloads.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () async {
                                setState(() {
                                  _isPlaying = true;
                                });
                                playMelody(index);
                              },
                              child: MelodyItem(
                                //Solves confusion between songs and melodies when adding to favourites
                                key: ValueKey('song_item'),
                                melody: _downloads[index],
                              ),
                            );
                          })
                      : Center(
                          child: Text(
                            'No downloads yet!',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
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
    );
  }

  Future<bool> _onBack() async {
    for (String path in _decryptedPaths) {
      File file = File(path);
      await file.delete();
    }
    print('decrypted files deleted');
    Navigator.of(context).pop();
    return false;
  }

  void playMelody(int index) {
    AppUtil.showLoader(context);
    // if (musicPlayer != null) {
    //   setState(() {
    //     musicPlayer.stop();
    //   });
    // }
    String path = EncryptionService.decryptFile(_downloads[index].audioUrl);
    _decryptedPaths.add(path);
    musicPlayer = MusicPlayer(
      url: path,
      isLocal: true,
      backColor: MyColors.lightPrimaryColor.withOpacity(.9),
    );
    setState(() {
      Constants.currentRoute = '/';
    });
    Navigator.of(context).pop();
  }
}
