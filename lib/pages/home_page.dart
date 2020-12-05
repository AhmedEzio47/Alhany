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
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import '../app_util.dart';
import 'singer_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController _tabController;
  int _page = 0;
  bool _isPlaying = false;

  PageController _pageController;

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
                child: Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                          onTap: (index) {
                            setState(() {
                              //_isPlaying = false;
                              _page = index;
                            });
                            _pageController.animateToPage(
                              index,
                              duration: Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                            );
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
                      MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _tabController.index = index;
                                _page = index;
                              });
                              _currentPage();
                            },
                            children: [_songsPage(), _melodiesPage(), _favouritesPage()],
                          ),
                        ),
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
                        color: MyColors.iconLightColor,
                      ),
                    ),
                  ),
                  alignment: Alignment.topRight,
                ),
              )),
              Positioned.fill(
                  child: Align(
                child: Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: Container(
                    height: 40,
                    width: 150,
                    child: Image.asset(
                      Strings.app_bar,
                    ),
                  ),
                ),
                alignment: Alignment.topCenter,
              )),
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
        break;
      case 1:
        getSingers();
        getRecords();
        break;
      case 2:
        getFavourites();
        break;
    }
  }

  List<String> _categories = [];
  Map<String, List<Singer>> _categorySingers = {};
  getCategories() async {
    List<String> categories = await DatabaseService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
    for (String category in categories) {
      List<Singer> singers = await DatabaseService.getSingersByCategory(category);
      if (mounted) {
        setState(() {
          _categorySingers.putIfAbsent(category, () => singers);
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
          return (_categorySingers[_categories[index]]?.length ?? 0) > 0
              ? Container(
                  height: 180,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _categories[index],
                          style: TextStyle(color: MyColors.textLightColor, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(top: 8),
                                color: Colors.black26,
                                child: ListView.builder(
                                    itemCount: _categorySingers[_categories[index]]?.length + 1,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index2) {
                                      return index2 < _categorySingers[_categories[index]]?.length
                                          ? InkWell(
                                              onTap: () {
                                                Navigator.of(context).pushNamed('/singer-page', arguments: {
                                                  'singer': _categorySingers[_categories[index]][index2],
                                                  'data_type': DataTypes.SONGS
                                                });
                                              },
                                              child: Container(
                                                height: 110,
                                                width: 110,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    CachedImage(
                                                      width: 100,
                                                      height: 100,
                                                      imageShape: BoxShape.circle,
                                                      imageUrl: _categorySingers[_categories[index]][index2]?.imageUrl,
                                                      defaultAssetImage: Strings.default_profile_image,
                                                    ),
                                                    Text(
                                                      _categorySingers[_categories[index]][index2]?.name,
                                                      style: TextStyle(
                                                        color: Colors.grey.shade300,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : _categorySingers[_categories[index]]?.length == 15
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
    List<Singer> singers = await DatabaseService.getSingersHaveMelodies();
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

  LinkedScrollControllerGroup _controllers;
  ScrollController _recordsScrollController = ScrollController();
  ScrollController _melodiesPageScrollController = ScrollController();
  recordListView() {
    return ListView.builder(
        shrinkWrap: true,
        controller: _recordsScrollController,
        itemCount: _records.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              setState(() {
                musicPlayer = MusicPlayer(
                  url: _records[index].url,
                  backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                  btnSize: 35,
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
    return SingleChildScrollView(
      controller: _melodiesPageScrollController,
      child: SizedBox(
        height: MediaQuery.of(context).size.height, // or something similar :)
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: Constants.language == 'en' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              height: 140,
              child: Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      color: Colors.black26,
                      child: ListView.builder(
                          itemCount: _singers.length + 1,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return index < _singers.length
                                ? InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushNamed('/singer-page',
                                          arguments: {'singer': _singers[index], 'data_type': DataTypes.MELODIES});
                                    },
                                    child: Container(
                                      height: 120,
                                      width: 120,
                                      child: Column(
                                        children: [
                                          CachedImage(
                                            width: 100,
                                            height: 100,
                                            imageShape: BoxShape.circle,
                                            imageUrl: _singers[index].imageUrl,
                                            defaultAssetImage: Strings.default_profile_image,
                                          ),
                                          Text(
                                            _singers[index].name,
                                            style: TextStyle(color: MyColors.textLightColor),
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
                                                  color: MyColors.darkPrimaryColor,
                                                  decoration: TextDecoration.underline),
                                            ),
                                          )),
                                        ),
                                      )
                                    : Container();
                          }),
                    ),
                  ),
                ],
              ),
            ),

            // Flexible(
            //     fit: FlexFit.tight,flex: 1, child:               Container(
            //   margin: EdgeInsets.symmetric(horizontal: 0),
            //   transform: Matrix4.translationValues(0.0, -30.0, 0.0),
            //   padding: EdgeInsets.symmetric(horizontal: 16),
            //   color: MyColors.lightPrimaryColor,
            //   width: MediaQuery.of(context).size.width,
            //   alignment: Alignment.centerRight,
            //   child: Text(
            //     language(en: 'Latest records', ar: 'آخر المنشورات'),
            //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            //   ),
            // ),
            // ),
            Flexible(
                fit: FlexFit.loose,
                flex: 8,
                child: MediaQuery.removePadding(context: context, removeTop: true, child: recordListView()))
          ],
        ),
      ),
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
                  padding: 4,
                  melody: _favourites[index],
                ),
              );
            })
        : Center(
            child: Text(
            language(en: 'No favourites yet', ar: 'لا توجد مفضلات'),
            style: TextStyle(color: MyColors.textLightColor),
          ));
  }

  @override
  void initState() {
    _pageController = PageController(
      initialPage: 0,
    );
    _tabController = TabController(vsync: this, length: 3, initialIndex: 0);
    _controllers = LinkedScrollControllerGroup();
    _recordsScrollController = _controllers.addAndGet();

    _recordsScrollController
      ..addListener(() {
        if (_recordsScrollController.offset >= _recordsScrollController.position.maxScrollExtent &&
            !_recordsScrollController.position.outOfRange) {
          print('reached the bottom');
          nextRecords();
        } else if (_recordsScrollController.offset <= _recordsScrollController.position.minScrollExtent &&
            !_recordsScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    _melodiesPageScrollController = _controllers.addAndGet();
    getCategories();
    super.initState();
  }

  @override
  void dispose() {
    _recordsScrollController.dispose();
    _melodiesPageScrollController.dispose();
    super.dispose();
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
