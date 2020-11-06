import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:flutter/material.dart';

class SingerPage extends StatefulWidget {
  final Singer singer;

  const SingerPage({Key key, this.singer}) : super(key: key);

  @override
  _SingerPageState createState() => _SingerPageState();
}

class _SingerPageState extends State<SingerPage> with TickerProviderStateMixin {
  TabController _tabController;
  int _page = 0;
  ScrollController _songsScrollController = ScrollController();
  List<Melody> _songs = [];

  bool _isPlaying = false;

  getSongs() async {
    List<Melody> songs = await DatabaseService.getSongsBySingerName(widget.singer.name);
    if (mounted) {
      setState(() {
        _songs = songs;
      });
    }
  }

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 2, initialIndex: 1);
    super.initState();
  }

  _currentPage() {
    switch (_page) {
      case 0:
        return Center(
          child: Text('لألحان'),
        );
      case 1:
        getSongs();
        return _songsPage();
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
                    padding: 0,
                    imageSize: 40,
                    isRounded: false,
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isPlaying = false;
          });
        },
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
              Container(
                height: 200,
                child: Stack(
                  children: [
                    CachedImage(
                      height: 200,
                      width: MediaQuery.of(context).size.width,
                      defaultAssetImage: Strings.default_cover_image,
                      imageUrl: widget.singer.coverUrl,
                      imageShape: BoxShape.rectangle,
                    ),
                    Positioned.fill(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 16),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: CachedImage(
                          height: 100,
                          width: 100,
                          defaultAssetImage: Strings.default_profile_image,
                          imageUrl: widget.singer.imageUrl,
                          imageShape: BoxShape.circle,
                        ),
                      ),
                    )),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            color: Colors.black.withOpacity(.8),
                            child: Text(
                              widget.singer.name,
                              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              TabBar(
                  onTap: (index) {
                    setState(() {
                      _page = index;
                    });
                  },
                  labelColor: MyColors.accentColor,
                  unselectedLabelColor: Colors.grey,
                  controller: _tabController,
                  tabs: [
                    Tab(
                      text: language(en: 'Melodies', ar: 'الألحان'),
                    ),
                    Tab(
                      text: language(en: 'Songs', ar: 'الأغاني'),
                    ),
                  ]),
              Expanded(child: _currentPage())
            ],
          ),
        ),
      ),
    );
  }
}
