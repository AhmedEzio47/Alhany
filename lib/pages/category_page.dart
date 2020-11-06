import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  final String category;

  const CategoryPage({Key key, this.category}) : super(key: key);
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Melody> _songs = [];
  ScrollController _songsScrollController = ScrollController();
  Timestamp lastVisiblePostSnapShot;

  bool _isPlaying = false;

  getSongs() async {
    List<Melody> songs =
        await DatabaseService.getSongsByCategory(widget.category);
    if (mounted) {
      setState(() {
        _songs = songs;
        if (_songs.length > 0)
          this.lastVisiblePostSnapShot = _songs.last.timestamp;
      });
    }
  }

  nextSongs() async {
    List<Melody> songs =
        await DatabaseService.getNextMelodies(lastVisiblePostSnapShot);
    if (songs.length > 0) {
      setState(() {
        songs.forEach((element) => _songs.add(element));
        this.lastVisiblePostSnapShot = songs.last.timestamp;
      });
    }
  }

  _songsPage() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: ListView.builder(
              shrinkWrap: true,
              controller: _songsScrollController,
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
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
                    padding: 8,
                    imageSize: 40,
                    isRounded: true,
                    key: ValueKey('song_item'),
                    melody: _songs[index],
                  ),
                );
              }),
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
    );
  }

  @override
  void initState() {
    getSongs();
    _songsScrollController
      ..addListener(() {
        if (_songsScrollController.offset >=
                _songsScrollController.position.maxScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print('reached the bottom');
          nextSongs();
        } else if (_songsScrollController.offset <=
                _songsScrollController.position.minScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isPlaying = false;
          });
        },
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: MyColors.primaryColor,
                image: DecorationImage(
                  colorFilter: new ColorFilter.mode(
                      Colors.black.withOpacity(0.1), BlendMode.dstATop),
                  image: AssetImage(Strings.default_bg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Text(
                      widget.category,
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    Expanded(
                      child: _songsPage(),
                    )
                  ],
                ),
              ),
            ),
            RegularAppbar(context)
          ],
        ),
      ),
    );
  }
}
