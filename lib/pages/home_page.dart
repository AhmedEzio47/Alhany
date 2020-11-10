import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/list_items/record_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_util.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController _tabController;
  int _page = 0;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            setState(() {
              _isPlaying = false;
            });
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: MyColors.primaryColor,
                  image: DecorationImage(
                    colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                    image: AssetImage(Strings.default_bg),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                          onTap: (index) {
                            setState(() {
                              _page = index;
                            });
                          },
                          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          labelColor: MyColors.accentColor,
                          unselectedLabelColor: Colors.grey,
                          controller: _tabController,
                          tabs: [
                            Tab(
                              text: language(en: 'Songs', ar: 'الأغاني'),
                            ),
                            Tab(
                              text: language(en: 'Melodies', ar: 'الألحان'),
                            ),
                            Tab(
                              text: language(en: 'Favourites', ar: 'المفضلات'),
                            )
                          ]),
                      Expanded(child: _currentPage())
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
              Positioned.fill(
                  child: Padding(
                padding: const EdgeInsets.only(right: 15.0, top: 40),
                child: Align(
                  child: Builder(
                    builder: (context) => InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/search-page');
                      },
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  alignment: Alignment.topRight,
                ),
              ))
            ],
          ),
        ),
        floatingActionButton: _page == 2
            ? FloatingActionButton(
                child: Icon(Icons.playlist_play),
                onPressed: () {
                  setState(() {
                    musicPlayer = MusicPlayer(
                      melodyList: _favourites,
                      backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                      initialDuration: 0,
                    );
                    _isPlaying = true;
                  });
                },
              )
            : null,
      ),
    );
  }

  _currentPage() {
    switch (_page) {
      case 0:
        getCategories();
        return _songsPage();
      case 1:
        getSingers();
        getRecords();
        return _melodiesPage();
      case 2:
        getFavourites();
        return _favouritesPage();
    }
  }

  List<String> _categories = [];
  Map<String, List<Melody>> _songs = {};
  getCategories() async {
    List<String> categories = await DatabaseService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
    for (String category in categories) {
      List<Melody> songs = await DatabaseService.getSongsByCategory(category);
      if (mounted) {
        setState(() {
          _songs.putIfAbsent(category, () => songs);
        });
      }
    }
  }

  Widget _songsPage() {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _categories?.length,
        itemBuilder: (context, index) {
          return (_songs[_categories[index]]?.length ?? 0) > 0
              ? Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  height: 215,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _categories[index],
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                  itemCount: _songs[_categories[index]]?.length + 1,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index2) {
                                    return index2 < _songs[_categories[index]]?.length
                                        ? InkWell(
                                            onTap: () {
                                              setState(() {
                                                musicPlayer = MusicPlayer(
                                                  melody: _songs[_categories[index]][index2],
                                                  title: _songs[_categories[index]][index2]?.name,
                                                  key: ValueKey(_songs[_categories[index]][index2]?.id),
                                                  url: _songs[_categories[index]][index2]?.audioUrl,
                                                  backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                                                  initialDuration: _songs[_categories[index]][index2]?.duration,
                                                );
                                                _isPlaying = true;
                                              });
                                            },
                                            child: Container(
                                              height: 150,
                                              width: 150,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  CachedImage(
                                                    width: 120,
                                                    height: 120,
                                                    imageShape: BoxShape.rectangle,
                                                    imageUrl: _songs[_categories[index]][index2]?.imageUrl,
                                                    defaultAssetImage: Strings.default_melody_image,
                                                  ),
                                                  Text(
                                                    _songs[_categories[index]][index2]?.name,
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                  Text(
                                                    _songs[_categories[index]][index2]?.singer,
                                                    style: TextStyle(color: Colors.grey.shade400),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        : _songs[_categories[index]]?.length == 15
                                            ? InkWell(
                                                onTap: () {
                                                  Navigator.of(context).pushNamed('/category-page',
                                                      arguments: {'category': _categories[index]});
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.only(right: 8.0, left: 8.0, bottom: 46),
                                                  child: Center(
                                                      child: Container(
                                                    padding: EdgeInsets.all(8),
                                                    color: MyColors.lightPrimaryColor,
                                                    child: Text(
                                                      'VIEW ALL',
                                                      style: TextStyle(
                                                          color: MyColors.darkPrimaryColor,
                                                          decoration: TextDecoration.underline),
                                                    ),
                                                  )),
                                                ),
                                              )
                                            : Container();
                                  }),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : Container();
        });
  }

  List<Singer> _singers = [];
  getSingers() async {
    List<Singer> singers = await DatabaseService.getSingers();
    if (mounted) {
      setState(() {
        _singers = singers;
      });
    }
  }

  Timestamp lastVisiblePostSnapShot;
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

  ScrollController _melodiesScrollController = ScrollController();
  recordListView() {
    return ListView.builder(
        shrinkWrap: true,
        controller: _melodiesScrollController,
        itemCount: _records.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              setState(() {
                musicPlayer = MusicPlayer(
                  url: _records[index].audioUrl,
                  backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                  btnSize: 35,
                  recordBtnVisible: true,
                  initialDuration: _records[index].duration,
                  playBtnPosition: PlayBtnPosition.left,
                );
                _isPlaying = true;
              });
            },
            child: RecordItem(
              record: _records[index],
            ),
          );
        });
  }

  Widget _melodiesPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: Constants.language == 'en' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 10,
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                    itemCount: _singers.length + 1,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return index < _singers.length
                          ? InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed('/singer-page', arguments: {'singer': _singers[index]});
                              },
                              child: Container(
                                height: 120,
                                width: 120,
                                child: Column(
                                  children: [
                                    CachedImage(
                                      width: 90,
                                      height: 90,
                                      imageShape: BoxShape.circle,
                                      imageUrl: _singers[index].imageUrl,
                                      defaultAssetImage: Strings.default_profile_image,
                                    ),
                                    Text(
                                      _singers[index].name,
                                      style: TextStyle(color: Colors.white),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : _singers.length == 15
                              ? InkWell(
                                  onTap: () {
                                    Navigator.of(context).pushNamed('/singers-page');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0, left: 8.0, bottom: 70),
                                    child: Center(
                                        child: Container(
                                      padding: EdgeInsets.all(8),
                                      color: MyColors.lightPrimaryColor,
                                      child: Text(
                                        'VIEW ALL',
                                        style: TextStyle(
                                            color: MyColors.darkPrimaryColor, decoration: TextDecoration.underline),
                                      ),
                                    )),
                                  ),
                                )
                              : Container();
                    }),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            padding: EdgeInsets.symmetric(horizontal: 16),
            color: MyColors.lightPrimaryColor,
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.centerRight,
            child: Text(
              language(en: 'Latest records', ar: 'آخر المنشورات'),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(flex: 7, child: recordListView())
      ],
    );
  }

  List<Melody> _favourites = [];
  getFavourites() async {
    List<Melody> favourites = await DatabaseService.getFavourites();
    if (mounted) {
      setState(() {
        _favourites = favourites;
      });
    }
  }

  _favouritesPage() {
    return _favourites.length > 0
        ? ListView.builder(
            itemCount: _favourites.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () async {
                  // if (musicPlayer != null) {
                  //   musicPlayer.stop();
                  // }
                  musicPlayer = MusicPlayer(
                    melody: _favourites[index],
                    key: ValueKey(_favourites[index].id),
                    url: _favourites[index].audioUrl,
                    backColor: Colors.white.withOpacity(.4),
                    initialDuration: _favourites[index].duration,
                    title: _favourites[index].name,
                  );
                  setState(() {
                    _isPlaying = true;
                  });
                },
                child: MelodyItem(
                  melody: _favourites[index],
                ),
              );
            })
        : Center(
            child: Text(
            language(en: 'No favourites yet', ar: 'لا توجد مفضلات'),
            style: TextStyle(color: Colors.white),
          ));
  }

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 3, initialIndex: 0);
    _melodiesScrollController
      ..addListener(() {
        if (_melodiesScrollController.offset >= _melodiesScrollController.position.maxScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print('reached the bottom');
          nextRecords();
        } else if (_melodiesScrollController.offset <= _melodiesScrollController.position.minScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    getCategories();
    super.initState();
  }

  var currentBackPressTime;
  Future<bool> _onBackPressed() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null || now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      AppUtil.showToast('Press back again to exit');
      return Future.value(false);
    }
    return Future.value(true);
  }
}