import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:flutter/material.dart';

class SongsPage extends StatefulWidget {
  final Singer singer;

  const SongsPage({Key key, this.singer}) : super(key: key);
  @override
  _SongsPageState createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  ScrollController _songsScrollController = ScrollController();
  List<Melody> _songs = [];

  bool _isPlaying = false;

  getSongs() async {
    List<Melody> songs = await DatabaseService.getSongsBySingerName(widget.singer.name);
    setState(() {
      _songs = songs;
    });
  }

  @override
  void initState() {
    getSongs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Constants.isAdmin
          ? FloatingActionButton(
              backgroundColor: MyColors.accentColor,
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).pushNamed('/upload-songs', arguments: {'singer': widget.singer.name});
              },
            )
          : null,
      body: GestureDetector(
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
                  color: MyColors.primaryColor,
                  image: DecorationImage(
                    colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                    image: AssetImage(Strings.default_bg),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 60,
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        controller: _songsScrollController,
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () async {
                              // if (musicPlayer != null) {
                              //   musicPlayer.stop();
                              // }

                              setState(() {
                                musicPlayer = MusicPlayer(
                                  url: _songs[index].audioUrl,
                                  backColor: MyColors.lightPrimaryColor,
                                  title: _songs[index].name,
                                  initialDuration: _songs[index].duration,
                                );
                                _isPlaying = true;
                              });
                            },
                            child: MelodyItem(
                              padding: 0,
                              imageSize: 40,
                              isRounded: false,
                              key: ValueKey('song_item'),
                              melody: _songs[index],
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Align(
                  child: Text(
                    widget.singer.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  alignment: Alignment.topCenter,
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
}
