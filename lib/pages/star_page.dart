import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:dubsmash/widgets/list_items/melody_item.dart';
import 'package:dubsmash/widgets/list_items/record_item.dart';
import 'package:dubsmash/widgets/music_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class StarPage extends StatefulWidget {
  @override
  _StarPageState createState() => _StarPageState();
}

class _StarPageState extends State<StarPage> with TickerProviderStateMixin {
  TabController _tabController;
  int _page = 0;

  List<Record> _records = [];
  getRecords() async {
    List<Record> records = await DatabaseService.getRecords();
    if (mounted) {
      setState(() {
        _records = records;
      });
    }
  }

  List<Melody> _melodies = [];
  getMelodies() async {
    List<Melody> melodies = await DatabaseService.getMelodies();
    if (mounted) {
      setState(() {
        _melodies = melodies;
      });
    }
  }

  List<Melody> _songs = [];
  getSongs() async {
    List<Melody> songs = await DatabaseService.getSongs();
    if (mounted) {
      setState(() {
        _songs = songs;
      });
    }
  }

  @override
  void initState() {
    getRecords();
    super.initState();
    _tabController = TabController(vsync: this, length: 3, initialIndex: 0);
  }

  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (musicPlayer != null) {
            musicPlayer.stop();
          }
          setState(() {
            _isPlaying = false;
          });
        },
        child: Container(
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
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  CachedImage(
                    width: 150,
                    height: 150,
                    imageShape: BoxShape.circle,
                    imageUrl: Constants.startUser?.profileImageUrl,
                    defaultAssetImage: Strings.default_profile_image,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TabBar(
                      onTap: (index) {
                        setState(() {
                          _page = index;
                        });
                      },
                      controller: _tabController,
                      unselectedLabelColor: MyColors.lightPrimaryColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: MyColors.darkPrimaryColor),
                      tabs: [
                        Tab(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: MyColors.darkPrimaryColor,
                                    width: 1)),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text("Records"),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: MyColors.darkPrimaryColor,
                                    width: 1)),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text("Melodies"),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: MyColors.darkPrimaryColor,
                                    width: 1)),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text("Songs"),
                            ),
                          ),
                        ),
                      ]),
                  _currentPage()
                ],
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
                  : Container()
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentPage() {
    switch (_page) {
      case 0:
        return Expanded(
          child: ListView.builder(
              itemCount: _records.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    if (musicPlayer != null) {
                      musicPlayer.stop();
                    }
                    musicPlayer = MusicPlayer(
                      url: _records[index].audioUrl,
                      backColor: Colors.white.withOpacity(.4),
                    );
                    setState(() {
                      _isPlaying = true;
                    });
                  },
                  child: RecordItem(
                    record: _records[index],
                  ),
                );
              }),
        );
        break;
      case 1:
        getMelodies();
        return Expanded(
          child: ListView.builder(
              itemCount: _melodies.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    if (musicPlayer != null) {
                      musicPlayer.stop();
                    }
                    musicPlayer = MusicPlayer(
                      url: _melodies[index].audioUrl,
                      backColor: Colors.white.withOpacity(.4),
                    );
                    setState(() {
                      _isPlaying = true;
                    });
                  },
                  child: MelodyItem(
                    melody: _melodies[index],
                  ),
                );
              }),
        );
        break;
      case 2:
        getSongs();
        return Expanded(
          child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    if (musicPlayer != null) {
                      musicPlayer.stop();
                    }
                    musicPlayer = MusicPlayer(
                      url: _songs[index].audioUrl,
                      backColor: Colors.white.withOpacity(.4),
                    );
                    setState(() {
                      _isPlaying = true;
                    });
                  },
                  child: MelodyItem(
                    melody: _songs[index],
                  ),
                );
              }),
        );
        break;

      default:
        return Container();
    }
  }
}
