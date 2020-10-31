import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:dubsmash/widgets/list_items/melody_item.dart';
import 'package:dubsmash/widgets/list_items/record_item2.dart';
import 'package:dubsmash/widgets/music_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class StarPage extends StatefulWidget {
  @override
  _StarPageState createState() => _StarPageState();
}

class _StarPageState extends State<StarPage> with TickerProviderStateMixin {
  TabController _tabController;
  ScrollController _mainScrollController = ScrollController();
  ScrollController _melodiesScrollController = ScrollController();
  ScrollController _recordsScrollController = ScrollController();
  ScrollController _songsScrollController = ScrollController();
  int _page = 0;

  Timestamp lastVisiblePostSnapShot;

  Color _searchColor = Colors.grey.shade300;

  TextEditingController _searchController = TextEditingController();

  List<Record> _records = [];
  getRecords() async {
    List<Record> records = await DatabaseService.getRecords();
    if (mounted) {
      setState(() {
        _records = records;
        if (_records.length > 0) this.lastVisiblePostSnapShot = records.last.timestamp;
      });
    }
  }

  nextRecords() async {
    List<Record> records = await DatabaseService.getNextRecords(lastVisiblePostSnapShot);
    if (records.length > 0) {
      setState(() {
        records.forEach((element) => _records.add(element));
        this.lastVisiblePostSnapShot = records.last.timestamp;
      });
    }
  }

  List<Melody> _melodies = [];
  List<Melody> _filteredMelodies = [];
  getMelodies() async {
    List<Melody> melodies = await DatabaseService.getMelodies();
    if (mounted) {
      setState(() {
        _melodies = melodies;
        if (_melodies.length > 0) this.lastVisiblePostSnapShot = melodies.last.timestamp;
      });
    }
  }

  nextMelodies() async {
    List<Melody> melodies = await DatabaseService.getNextMelodies(lastVisiblePostSnapShot);
    if (melodies.length > 0) {
      setState(() {
        melodies.forEach((element) => _melodies.add(element));
        this.lastVisiblePostSnapShot = melodies.last.timestamp;
      });
    }
  }

  searchMelodies(String text) async {
    List<Melody> filteredMelodies = await DatabaseService.searchMelodies(text);
    if (mounted) {
      setState(() {
        _filteredMelodies = filteredMelodies;
      });
    }
  }

  List<Melody> _songs = [];
  List<Melody> _filteredSongs = [];
  getSongs() async {
    List<Melody> songs = await DatabaseService.getSongs();
    if (mounted) {
      setState(() {
        _songs = songs;
        if (_songs.length > 0) this.lastVisiblePostSnapShot = songs.last.timestamp;
      });
    }
  }

  nextSongs() async {
    List<Melody> songs = await DatabaseService.getNextSongs(lastVisiblePostSnapShot);
    if (songs.length > 0) {
      setState(() {
        songs.forEach((element) => _songs.add(element));
        this.lastVisiblePostSnapShot = songs.last.timestamp;
      });
    }
  }

  searchSongs(String text) async {
    List<Melody> filteredSongs = await DatabaseService.searchSongs(text);
    if (mounted) {
      setState(() {
        _filteredSongs = filteredSongs;
      });
    }
  }

  @override
  void initState() {
    getRecords();
    super.initState();
    _tabController = TabController(vsync: this, length: 3, initialIndex: 0);

    _melodiesScrollController
      ..addListener(() {
        if (_melodiesScrollController.offset >= _melodiesScrollController.position.maxScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print('reached the bottom');
          if (!_isSearching) nextMelodies();
        } else if (_melodiesScrollController.offset <= _melodiesScrollController.position.minScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });

    _songsScrollController
      ..addListener(() {
        if (_songsScrollController.offset >= _songsScrollController.position.maxScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print('reached the bottom');
          if (!_isSearching) nextSongs();
        } else if (_songsScrollController.offset <= _songsScrollController.position.minScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
  }

  bool _isPlaying = false;
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // if (musicPlayer != null) {
          //   musicPlayer.stop();
          // }
          setState(() {
            _isPlaying = false;
            _isSearching = false;
          });
        },
        child: Stack(
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
                  colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                  image: AssetImage(Strings.default_bg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 70,
                  ),
                  CachedImage(
                    width: 150,
                    height: 150,
                    imageShape: BoxShape.circle,
                    imageUrl: Constants.startUser?.profileImageUrl,
                    defaultAssetImage: Strings.default_profile_image,
                  ),
                  SizedBox(
                    height: 30,
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
                      indicator:
                          BoxDecoration(borderRadius: BorderRadius.circular(50), color: MyColors.darkPrimaryColor),
                      tabs: [
                        Tab(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: MyColors.darkPrimaryColor, width: 1)),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(language(en: "Records", ar: 'التسجيلات')),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: MyColors.darkPrimaryColor, width: 1)),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(language(en: 'Melodies', ar: 'الألحان')),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: MyColors.darkPrimaryColor, width: 1)),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(language(en: "Songs", ar: 'الأغاني')),
                            ),
                          ),
                        ),
                      ]),
                  Expanded(child: _currentPage())
                ],
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
            _page != 0 ? _searchBar() : Container(),
          ],
        ),
      ),
      floatingActionButton: Constants.isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.add_circle,
                color: MyColors.primaryColor,
              ),
              onPressed: () async {
                AppUtil.showAlertDialog(
                    context: context,
                    message: language(en: 'What do you want to upload?', ar: 'ما الذي تريد رفعه؟'),
                    firstBtnText: language(en: 'Melody', ar: 'لحن'),
                    firstFunc: () async {
                      Navigator.of(context).pop();
                      AppUtil.showAlertDialog(
                          context: context,
                          message: language(
                              en: 'Single level or multi-level melody?', ar: 'لحن مستوى واحد أم متعدد المستويات؟'),
                          firstBtnText: language(en: 'Single', ar: 'أحادي'),
                          firstFunc: () async {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/upload-single-level-melody');
                          },
                          secondBtnText: language(en: 'Multi level', ar: 'متعدد المستويات'),
                          secondFunc: () async {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/upload-multi-level-melody');
                          });
                    },
                    secondBtnText: language(en: 'Song', ar: 'أغنية'),
                    secondFunc: () async {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/upload-songs');
                    });
              },
            )
          : null,
    );
  }

  Widget _currentPage() {
    switch (_page) {
      case 0:
        return ListView.builder(
            shrinkWrap: true,
            controller: _recordsScrollController,
            itemCount: _records.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () async {
                  // if (musicPlayer != null) {
                  //   musicPlayer.stop();
                  // }

                  setState(() {
                    musicPlayer = MusicPlayer(
                      key: ValueKey(_records[index].id),
                      url: _records[index].audioUrl,
                      backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                      initialDuration: _records[index].duration,
                    );
                    _isPlaying = true;
                  });
                },
                child: RecordItem2(
                  record: _records[index],
                  key: UniqueKey(),
                ),
              );
            });
        break;
      case 1:
        getMelodies();
        return _isSearching
            ? ListView.builder(
                shrinkWrap: true,
                controller: _melodiesScrollController,
                itemCount: _filteredMelodies.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      // if (musicPlayer != null) {
                      //   musicPlayer.stop();
                      // }

                      setState(() {
                        musicPlayer = MusicPlayer(
                          key: ValueKey(_filteredMelodies[index].id),
                          url: _filteredMelodies[index].audioUrl,
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _filteredMelodies[index].name,
                          btnSize: 30,
                          recordBtnVisible: true,
                          initialDuration: _filteredMelodies[index].duration,
                          melody: _filteredMelodies[index],
                        );
                        _isPlaying = true;
                      });
                    },
                    child: MelodyItem(
                      context: context,
                      key: ValueKey('melody_item'),
                      melody: _filteredMelodies[index],
                    ),
                  );
                })
            : ListView.builder(
                shrinkWrap: true,
                controller: _melodiesScrollController,
                itemCount: _melodies.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      // if (musicPlayer != null) {
                      //   musicPlayer.stop();
                      // }

                      setState(() {
                        musicPlayer = MusicPlayer(
                          key: ValueKey(_melodies[index].id),
                          url: _melodies[index].audioUrl ?? _melodies[index].levelUrls.values.elementAt(0),
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _melodies[index].name,
                          btnSize: 30,
                          recordBtnVisible: true,
                          initialDuration: _melodies[index].duration,
                          melody: _melodies[index],
                        );
                        _isPlaying = true;
                      });
                    },
                    child: MelodyItem(
                      context: context,
                      key: ValueKey('melody_item'),
                      melody: _melodies[index],
                    ),
                  );
                });
        break;
      case 2:
        getSongs();
        return _isSearching
            ? ListView.builder(
                shrinkWrap: true,
                controller: _songsScrollController,
                itemCount: _filteredSongs.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      // if (musicPlayer != null) {
                      //   musicPlayer.stop();
                      // }

                      setState(() {
                        musicPlayer = MusicPlayer(
                          key: ValueKey(_filteredSongs[index].id),
                          url: _filteredSongs[index].audioUrl,
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _filteredSongs[index].name,
                          initialDuration: _filteredSongs[index].duration,
                        );
                        _isPlaying = true;
                      });
                    },
                    child: MelodyItem(
                      //Solves confusion between songs and melodies when adding to favourites
                      context: context,
                      key: ValueKey('song_item'),
                      melody: _filteredSongs[index],
                    ),
                  );
                })
            : ListView.builder(
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
                          key: ValueKey(_songs[index].id),
                          url: _songs[index].audioUrl,
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _songs[index].name,
                          initialDuration: _songs[index].duration,
                        );
                        _isPlaying = true;
                      });
                    },
                    child: MelodyItem(
                      //Solves confusion between songs and melodies when adding to favourites
                      context: context,
                      key: ValueKey('song_item'),
                      melody: _songs[index],
                    ),
                  );
                });
        break;

      default:
        return Container();
    }
  }

  Widget _searchBar() {
    return Positioned.fill(
        child: Align(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: InkWell(
          onTap: () {
            setState(() {
              _isSearching = true;
            });
          },
          child: _isSearching
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    style: TextStyle(color: _searchColor),
                    controller: _searchController,
                    onChanged: (text) async {
                      if (_page == 1) {
                        await searchMelodies(text.toLowerCase());
                      } else if (_page == 2) {
                        await searchSongs(text.toLowerCase());
                      }
                    },
                    decoration: InputDecoration(
                        fillColor: _searchColor,
                        focusColor: _searchColor,
                        hoverColor: _searchColor,
                        hintText: 'Search ${_page == 1 ? 'melodies' : _page == 2 ? 'songs' : ''}...',
                        disabledBorder: new UnderlineInputBorder(
                            borderSide: new BorderSide(
                          color: _searchColor,
                        )),
                        border: new UnderlineInputBorder(
                            borderSide: new BorderSide(
                          color: _searchColor,
                        )),
                        enabledBorder: new UnderlineInputBorder(
                            borderSide: new BorderSide(
                          color: _searchColor,
                        )),
                        prefixIcon: Icon(
                          Icons.search,
                          color: _searchColor,
                        ),
                        suffixIcon: InkWell(
                          onTap: () {
                            _searchController.clear();
                            _filteredSongs = [];
                            _filteredMelodies = [];
                          },
                          child: Icon(
                            Icons.close,
                            color: _searchColor,
                          ),
                        ),
                        hintStyle: TextStyle(color: _searchColor)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 20.0, top: 20),
                  child: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      alignment: Alignment.topRight,
    ));
  }
}
