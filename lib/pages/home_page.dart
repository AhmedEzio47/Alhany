import 'dart:async';

import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/category_model.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/pages/song_page.dart';
import 'package:Alhany/provider/revenuecat.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/permissions_service.dart';
import 'package:Alhany/services/purchase_api.dart';
import 'package:Alhany/services/remote_config_service.dart';
import 'package:Alhany/services/sqlite_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/list_items/record_item.dart';
import 'package:Alhany/widgets/local_music_player.dart';
import 'package:Alhany/widgets/paywall_widget.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:provider/provider.dart';

import '../app_util.dart';
import 'singer_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  ScrollController _exclusivesScrollController = ScrollController();
  List<Melody> _exclusives = [];
  int _page = 0;
  bool _isSearching = false;
  List<Melody> _filteredexclusives = [];
  bool _isPlaying = false;

  PageController _pageController;

  TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider<RevenueCatProvider>(
      create: (context) => RevenueCatProvider(),lazy: false,
      child: WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          drawer: BuildDrawer(),
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
                      colorFilter: new ColorFilter.mode(
                          Colors.black.withOpacity(0.1), BlendMode.dstATop),
                      image: AssetImage(Strings.default_bg),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: Sizes.home_screen_page_view_padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TabBar(
                            onTap: (index) {
                              setState(() {
                                _page = index;
                              });
                              _pageController.animateToPage(
                                index,
                                duration: Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                              );
                            },
                            labelStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                                text: language(en: 'Records', ar: 'تسجيلات'),
                              ),
                              Tab(
                                text: language(en: 'Exclusives', ar: 'الحصري'),
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
                              children: [
                                _songsPage(),
                                _melodiesPage(),
                                _recordsPage(),
                                _favouritesPage()
                              ],
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
                    child: Align(
                  child: RegularAppbar(
                    context,
                    color: Colors.black,
                    height: Sizes.appbar_height,
                    margin: 25,
                    leading: Padding(
                      padding: const EdgeInsets.only(
                        left: 15.0,
                      ),
                      child: Builder(
                        builder: (context) => InkWell(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Icon(
                            Icons.menu,
                            color: MyColors.accentColor,
                          ),
                        ),
                      ),
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Builder(
                        builder: (context) => InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed('/search-page');
                          },
                          child: Icon(
                            Icons.search,
                            color: MyColors.accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  alignment: Alignment.topCenter,
                )),
              ],
            ),
          ),
          floatingActionButton:
              _page == 3 && (_favourites.length + _boughtSongs.length) > 1
                  ? FloatingActionButton(
                      child: Icon(Icons.playlist_play),
                      onPressed: () {
                        if (_favourites.isEmpty) {
                          return;
                        }
                        setState(() {
                          musicPlayer = LocalMusicPlayer(
                            melodyList: [..._boughtSongs, ..._favourites],
                            backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                            initialDuration: 0,
                          );
                          _isPlaying = true;
                        });
                      },
                    )
                  : null,
        ),
      ),
    );
  }

  _currentPage() {
    switch (_page) {
      case 0:
        getCategories();
        break;
      case 1:
        //getSingers();
        getMelodies();
        break;
      case 2:
        getRecords();
        break;
      case 3:
        exclusivesWidget();
        //getFavourites();
        //getBoughtSongs();
        break;
    }
  }

  List<Category> _categories = [];
  Map<Category, List<Singer>> _categorySingers = {};
  getCategories() async {
    List<Category> categories = await DatabaseService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
    for (Category category in categories) {
      List<Singer> singers =
          await DatabaseService.getSingersByCategory(category.name);
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
                  height: Sizes.singer_box + 100,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Constants.isAdmin ?? false
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _categories[index].name,
                                  style: TextStyle(
                                      color: MyColors.textLightColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: MyColors.iconLightColor,
                                    ),
                                    onPressed: () async {
                                      await editCategory(_categories[index]);
                                    })
                              ],
                            )
                          : Center(
                              child: Text(
                                _categories[index].name,
                                style: TextStyle(
                                    color: MyColors.textLightColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
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
                                    itemCount:
                                        _categorySingers[_categories[index]]
                                                ?.length ??
                                            0 + 1,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index2) {
                                      return index2 <
                                              _categorySingers[
                                                      _categories[index]]
                                                  ?.length
                                          ? InkWell(
                                              onTap: () {
                                                Navigator.of(context).pushNamed(
                                                    '/singer-page',
                                                    arguments: {
                                                      'singer':
                                                          _categorySingers[
                                                                  _categories[
                                                                      index]]
                                                              [index2],
                                                      'data_type':
                                                          DataTypes.SONGS
                                                    });
                                              },
                                              child: Container(
                                                key: ValueKey(_categorySingers[
                                                            _categories[index]]
                                                        [index2]
                                                    .id),
                                                height: Sizes.singer_box,
                                                width: Sizes.singer_box,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    CachedImage(
                                                      width:
                                                          Sizes.singer_box - 10,
                                                      height:
                                                          Sizes.singer_box - 10,
                                                      imageShape:
                                                          BoxShape.rectangle,
                                                      imageUrl: _categorySingers[
                                                                  _categories[
                                                                      index]]
                                                              [index2]
                                                          ?.imageUrl,
                                                      defaultAssetImage: Strings
                                                          .default_profile_image,
                                                    ),
                                                    Container(
                                                      width: 100,
                                                      child: Text(
                                                        _categorySingers[
                                                                    _categories[
                                                                        index]]
                                                                [index2]
                                                            ?.name,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade300,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : _categorySingers[_categories[index]]
                                                      ?.length ==
                                                  15
                                              ? InkWell(
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .pushNamed(
                                                            '/category-page',
                                                            arguments: {
                                                          'category':
                                                              _categories[index]
                                                        });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0,
                                                            left: 8.0,
                                                            bottom: 46),
                                                    child: Center(
                                                        child: Container(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      color: MyColors
                                                          .lightPrimaryColor,
                                                      child: Text(
                                                        'VIEW ALL',
                                                        style: TextStyle(
                                                            color: MyColors
                                                                .darkPrimaryColor,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline),
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
        if (_records.length > 0)
          this.lastVisiblePostSnapShot = records.last.timestamp;
      });
    }
  }

  nextRecords() async {
    List<Record> records =
        await DatabaseService.getNextRecords(lastVisiblePostSnapShot);
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
              // setState(() {
              //   musicPlayer = LocalMusicPlayer(
              //     url: _records[index].url,
              //     backColor: MyColors.lightPrimaryColor.withOpacity(.8),
              //     btnSize: 35,
              //     initialDuration: _records[index].duration,
              //     playBtnPosition: PlayBtnPosition.left,
              //   );
              //   _isPlaying = true;
              // });
            },
            child: RecordItem(
              key: ValueKey(_records[index].id),
              record: _records[index],
            ),
          );
        });
  }

  Widget _melodiesPage() {
    return SizedBox(
      height: MediaQuery.of(context).size.height, // or something similar :)
      child: CustomScrollView(
        controller: _melodiesPageScrollController,
        slivers: [
          ///Mod 1
          // SliverList(
          //   delegate: SliverChildListDelegate([
          //     Container(
          //       height: 164,
          //       child: Row(
          //         children: [
          //           Flexible(
          //             fit: FlexFit.tight,
          //             flex: 3,
          //             child: Container(
          //               padding: EdgeInsets.symmetric(vertical: 8),
          //               color: Colors.black26,
          //               child: ListView.builder(
          //                   itemCount: _singers.length + 1,
          //                   scrollDirection: Axis.horizontal,
          //                   itemBuilder: (context, index) {
          //                     return index < _singers.length
          //                         ? InkWell(
          //                             onTap: () {
          //                               Navigator.of(context).pushNamed(
          //                                   '/singer-page',
          //                                   arguments: {
          //                                     'singer': _singers[index],
          //                                     'data_type': DataTypes.MELODIES
          //                                   });
          //                             },
          //                             child: Container(
          //                               key: ValueKey(_singers[index].id),
          //                               height: 120,
          //                               width: 120,
          //                               child: Column(
          //                                 children: [
          //                                   CachedImage(
          //                                     width: 100,
          //                                     height: 100,
          //                                     imageShape: BoxShape.circle,
          //                                     imageUrl:
          //                                         _singers[index].imageUrl,
          //                                     defaultAssetImage:
          //                                         Strings.default_profile_image,
          //                                   ),
          //                                   Container(
          //                                     width: 100,
          //                                     child: Text(
          //                                       _singers[index].name,
          //                                       maxLines: 2,
          //                                       overflow: TextOverflow.visible,
          //                                       textAlign: TextAlign.center,
          //                                       style: TextStyle(
          //                                           color: MyColors
          //                                               .textLightColor),
          //                                     ),
          //                                   )
          //                                 ],
          //                               ),
          //                             ),
          //                           )
          //                         : _singers.length == 15
          //                             ? InkWell(
          //                                 onTap: () {
          //                                   Navigator.of(context)
          //                                       .pushNamed('/singers-page');
          //                                 },
          //                                 child: Padding(
          //                                   padding: const EdgeInsets.only(
          //                                       right: 8.0,
          //                                       left: 8.0,
          //                                       bottom: 70),
          //                                   child: Center(
          //                                       child: Container(
          //                                     padding: EdgeInsets.all(8),
          //                                     color: MyColors.lightPrimaryColor,
          //                                     child: Text(
          //                                       'VIEW ALL',
          //                                       style: TextStyle(
          //                                           color: MyColors
          //                                               .darkPrimaryColor,
          //                                           decoration: TextDecoration
          //                                               .underline),
          //                                     ),
          //                                   )),
          //                                 ),
          //                               )
          //                             : Container();
          //                   }),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ]),
          // ),
          SliverList(
            delegate: SliverChildListDelegate([_melodiesList()]),
          ),
        ],
      ),
    );
  }

  Widget _recordsPage() {
    return MediaQuery.removePadding(
        context: context, removeTop: true, child: recordListView());
  }

  _melodiesList() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListView.builder(
          primary: false,
          shrinkWrap: true,
          //controller: _melodiesPageScrollController,
          itemCount: _melodies.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () async {
                setState(() {
                  musicPlayer = LocalMusicPlayer(
                    key: ValueKey(_melodies[index].id),
                    melodyList: [_melodies[index]],
                    backColor: MyColors.lightPrimaryColor,
                    title: _melodies[index].name,
                    initialDuration: _melodies[index].duration,
                    isRecordBtnVisible: true,
                  );
                  _isPlaying = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) {
                      return SongPage(
                        song: _melodies[index],
                      );
                    }));
                  },
                  child: MelodyItem(
                    padding: 0,
                    imageSize: 40,
                    showPrice: false,
                    showFavBtn: false,
                    isRounded: false,
                    key: ValueKey('melody_item'),
                    melody: _melodies[index],
                  ),
                ),
              ),
            );
          }),
    );
  }

  List _melodies = [];
  getMelodies() async {
    List<Melody> melodies = await DatabaseService.getMelodies();
    if (mounted) {
      setState(() {
        _melodies = melodies;
      });
    }
  }

  nextMelodies() async {
    List<Melody> melodies =
        await DatabaseService.getNextMelodies(lastVisiblePostSnapShot);
    if (melodies.length > 0) {
      setState(() {
        melodies.forEach((element) => _melodies.add(element));
        this.lastVisiblePostSnapShot = melodies.last.timestamp;
      });
    }
  }

  List<Melody> _favourites = [];
  List<Melody> _boughtSongs = [];
  getFavourites() async {
    List<Melody> favourites = await DatabaseService.getFavourites();
    if (mounted) {
      setState(() {
        _favourites = favourites;
      });
    }
  }

  getBoughtSongs() async {
    if (Constants.currentUser == null) return;
    List<Melody> boughtSongs = await DatabaseService.getBoughtSongs();
    if (mounted) {
      setState(() {
        _boughtSongs = boughtSongs;
      });
    }
  }

  ScrollController _favScrollController = ScrollController();
  _favouritesPage() {
    return CustomScrollView(
      controller: _favScrollController,
      slivers: [
        // if (_boughtSongs.isNotEmpty)
        //   SliverToBoxAdapter(
        //     child: Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: Align(
        //         alignment: Constants.language == 'ar'
        //             ? Alignment.centerRight
        //             : Alignment.centerLeft,
        //         child: Text(
        //           language(ar: 'الأغاني المشتراة', en: 'Bought songs'),
        //           style: TextStyle(color: MyColors.textLightColor),
        //         ),
        //       ),
        //     ),
        //   ),
        // if (_boughtSongs.isNotEmpty)
        //   SliverList(
        //     delegate: SliverChildListDelegate([
        //       ListView.builder(
        //           physics: NeverScrollableScrollPhysics(),
        //           shrinkWrap: true,
        //           itemCount: _boughtSongs.length,
        //           itemBuilder: (context, index) {
        //             return InkWell(
        //               onTap: () async {
        //                 _boughtSongsIndex = index;
        //                 musicPlayer = LocalMusicPlayer(
        //                   checkPrice: false,
        //                   onDownload: downloadSong,
        //                   melodyList: [_boughtSongs[index]],
        //                   key: ValueKey(_boughtSongs[index].id),
        //                   backColor: Colors.black.withOpacity(.7),
        //                   initialDuration: _boughtSongs[index].duration,
        //                   title: _boughtSongs[index].name,
        //                 );
        //                 setState(() {
        //                   _isPlaying = true;
        //                 });
        //               },
        //               child: MelodyItem(
        //                 showPrice: false,
        //                 padding: 4,
        //                 melody: _boughtSongs[index],
        //               ),
        //             );
        //           })
        //     ]),
        //   ),
        // if (_favourites.isNotEmpty)
        //   SliverToBoxAdapter(
        //     child: Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: Align(
        //         alignment: Constants.language == 'ar'
        //             ? Alignment.centerRight
        //             : Alignment.centerLeft,
        //         child: Text(
        //           language(ar: 'المفضلات', en: 'Favorites'),
        //           style: TextStyle(color: MyColors.textLightColor),
        //         ),
        //       ),
        //     ),
        //   ),
        SliverList(
            delegate: SliverChildListDelegate([
          _exclusives.isNotEmpty
              ? exclusivesWidget()
              : Center(
                  child: Text(
                  language(en: 'No exclusives yet', ar: 'لا توجد حصريات'),
                  style: TextStyle(color: MyColors.textLightColor),
                ))
        ])),
      ],
    );
  }

  @override
  void initState() {
    // SystemChannels.lifecycle.setMessageHandler((msg) {
    //   print('SystemChannels> $msg');
    //   switch (msg) {
    //     case "AppLifecycleState.resumed":
    //       if (NotificationHandler.lastNotification != null) {
    //         NotificationHandler.navigateToScreen(
    //             context,
    //             NotificationHandler.lastNotification['type'],
    //             NotificationHandler.lastNotification['object_id']);
    //       }
    //       NotificationHandler.lastNotification = null;
    //       break;
    //     default:
    //   }
    //   return;
    // });
    _pageController = PageController(
      initialPage: 0,
    );
    _tabController = TabController(vsync: this, length: 4, initialIndex: 0);
    _exclusivesScrollController
      ..addListener(() {
        if (_exclusivesScrollController.offset >=
                _exclusivesScrollController.position.maxScrollExtent &&
            !_exclusivesScrollController.position.outOfRange) {
          print('reached the bottom');
          if (!_isSearching) nextExclusives();
        } else if (_exclusivesScrollController.offset <=
                _exclusivesScrollController.position.minScrollExtent &&
            !_exclusivesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    _controllers = LinkedScrollControllerGroup();
    _recordsScrollController = _controllers.addAndGet();
    _melodiesPageScrollController
      ..addListener(() {
        if (_melodiesPageScrollController.offset >=
                _melodiesPageScrollController.position.maxScrollExtent &&
            !_melodiesPageScrollController.position.outOfRange) {
          print('reached the bottom');
          nextMelodies();
        } else if (_melodiesPageScrollController.offset <=
                _melodiesPageScrollController.position.minScrollExtent &&
            !_melodiesPageScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    _recordsScrollController
      ..addListener(() {
        if (_recordsScrollController.offset >=
                _recordsScrollController.position.maxScrollExtent &&
            !_recordsScrollController.position.outOfRange) {
          print('reached the bottom');
          nextRecords();
        } else if (_recordsScrollController.offset <=
                _recordsScrollController.position.minScrollExtent &&
            !_recordsScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    _melodiesPageScrollController = _controllers.addAndGet();
    getExclusives();
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
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      AppUtil.showToast(
          language(en: 'Press back again to exit', ar: 'اضغط مرة أخرى للخروج'));
      return Future.value(false);
    }
    return Future.value(true);
  }

  getExclusives() async {
    List<Melody> exclusives = await DatabaseService.getStarExclusives();
    if (mounted) {
      setState(() {
        _exclusives = exclusives;
        if (_exclusives.length > 0)
          this.lastVisiblePostSnapShot = exclusives.last.timestamp;
      });
    }
  }

  nextExclusives() async {
    List<Melody> exclusives =
        await DatabaseService.getNextExclusives(lastVisiblePostSnapShot);
    if (exclusives.length > 0) {
      setState(() {
        exclusives.forEach((element) => _exclusives.add(element));
        this.lastVisiblePostSnapShot = exclusives.last.timestamp;
      });
    }
  }

  editCategory(Category category) async {
    setState(() {
      _categoryController.text = category.name;
    });
    Navigator.of(context).push(CustomModal(
        child: Container(
      height: 200,
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _categoryController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(hintText: 'New name'),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_categoryController.text.trim().isEmpty) {
                AppUtil.showToast(language(
                    en: 'Please enter a name', ar: 'من فضلك ادخل اسم'));
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              List<Singer> singers =
                  await DatabaseService.getSingersByCategory(category.name);
              for (Singer singer in singers) {
                await singersRef
                    .doc(singer.id)
                    .update({'category': _categoryController.text});
              }
              await categoriesRef.doc(category.id).update({
                'name': _categoryController.text,
                'search': searchList(_categoryController.text),
              });
              AppUtil.showToast(
                  language(en: 'Name Updated', ar: 'تم تحديث الإسم'));
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
            },
            color: MyColors.primaryColor,
            child: Text(
              'Update',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    )));
  }

  int _boughtSongsIndex = 0;
  downloadSong() async {
    AppUtil.showLoader(context);
    Melody storedMelody =
        await MelodySqlite.getMelodyWithId(_boughtSongs[_boughtSongsIndex].id);
    if (storedMelody != null) {
      AppUtil.showToast('Already downloaded');
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/downloads');
      return;
    }
    String path;
    if (_boughtSongs[_boughtSongsIndex].songUrl != null) {
      if (!(await PermissionsService().hasStoragePermission())) {
        await PermissionsService().requestStoragePermission(context);
      }
      await AppUtil.deleteFiles();
      await AppUtil.createAppDirectory();
      path = await AppUtil.downloadFile(_boughtSongs[_boughtSongsIndex].songUrl,
          toDownloads: true);
    }

    Melody melody = Melody(
        id: _boughtSongs[_boughtSongsIndex].id,
        duration: _boughtSongs[_boughtSongsIndex].duration,
        imageUrl: _boughtSongs[_boughtSongsIndex].imageUrl,
        name: _boughtSongs[_boughtSongsIndex].name,
        songUrl: path);

    if (storedMelody == null) {
      await MelodySqlite.insert(melody);
    }
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed('/downloads');
  }

  deleteExclusive(Melody melody) async {
    if (!Constants.isAdmin) return;
    AppUtil.showAlertDialog(
        context: context,
        message: 'Are you sure you want to delete this exclusive?',
        firstBtnText: 'Yes',
        firstFunc: () async {
          Navigator.of(context).pop();
          AppUtil.showLoader(context);
          await DatabaseService.deleteExclusive(melody);

          AppUtil.showToast(language(en: 'Deleted!', ar: 'تم الحذف'));
          Navigator.of(context).pushReplacementNamed('/');
        },
        secondBtnText: 'No',
        secondFunc: () {
          Navigator.of(context).pop();
        });
  }

  dynamic fetchExclusiveFee() async {
    return RemoteConfigService.getString('exclusives_fee');
  }

  Future subscribe() async {
    String exFee = await fetchExclusiveFee();
    AppUtil.executeFunctionIfLoggedIn(context, () async {
      final success = await Navigator.of(context)
          .pushNamed('/payment-home', arguments: {'amount': exFee});
      if (success ?? false) {
        await usersRef
            .doc(Constants.currentUserID)
            .update({'exclusive_last_date': FieldValue.serverTimestamp()});

        Constants.currentUser =
            await DatabaseService.getUserWithId(Constants.currentUserID);
        setState(() {});
      }
    });
  }

  Future fetchOffers() async {
    final offerings = await PurchaseApi.fetchOffers(all: false);
    print('fetchOffers.offerings $offerings');
    if (offerings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(language(
            ar: 'هذا العنصر غير متوفر للشراء حالياً',
            en: 'The app currently has no offers')),
      ));
    } else {
      //final offer = offerings.first;
      //print('Offer: $offer');
      final packages = offerings
          .map((offer) => offer.availablePackages)
          .expand((pair) => pair)
          .toList();
      _settingModalBottomSheet(packages);
    }
  }

  validateSubscription(Entitlement entitlement, Function showUI) {
    switch (entitlement) {
      case Entitlement.exclusives:
        showUI();
        return;
      case Entitlement.free:
      default:
      return AppUtil.showAlertDialog(
        context: context,
        firstFunc: fetchOffers,
        firstBtnText: language(ar: 'اشتراك', en: 'Subscribe'),
        message: language(
            ar: 'من فضلك قم بالاشتراك لكي تستمع للحصريات',
            en: 'Please subscribe in order to listen to exclusives'),
        secondBtnText: language(ar: 'إلغاء', en: 'Cancel'),
        secondFunc: () => Navigator.of(context).pop(),
      );
    }
  }

  searchExclusives(String text) async {
    List<Melody> filteredExclusives =
        await DatabaseService.searchExclusives(text);
    if (mounted) {
      setState(() {
        _filteredexclusives = filteredExclusives;
      });
    }
  }

  Widget exclusivesWidget() {
    return GridView.builder(
        shrinkWrap: true,
        primary: false,
        controller: _exclusivesScrollController,
        itemCount: _exclusives.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: .8,
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          return InkWell(
            onLongPress: () => deleteExclusive(_exclusives[index]),
            onTap: () async {
              print('EntitlementStatus= ${Provider.of<RevenueCatProvider>(context, listen: false).entitlement}');
              validateSubscription(Provider.of<RevenueCatProvider>(context, listen: false).entitlement, () {
                setState(() {
                  print('current user2: ${Constants.currentUser}');
                  musicPlayer = LocalMusicPlayer(
                    checkPrice: false,
                    key: ValueKey(_exclusives[index].id),
                    backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                    title: _exclusives[index].name,
                    btnSize: 30,
                    initialDuration: _exclusives[index].duration,
                    melodyList: [_exclusives[index]],
                    isRecordBtnVisible: true,
                  );
                  _isPlaying = true;
                });
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              key: ValueKey('melody_item'),
              child: Column(
                children: [
                  CachedImage(
                    imageUrl: _exclusives[index].imageUrl,
                    width: 200,
                    height: 200,
                    defaultAssetImage: Strings.default_melody_image,
                    imageShape: BoxShape.rectangle,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    _exclusives[index].name,
                    style: TextStyle(color: MyColors.textLightColor),
                  )
                ],
              ),
            ),
          );
        });
  }

  void _settingModalBottomSheet(List packages) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return PaywallWidget(
            packages: packages,
            title: language(
                ar: '🌟 الاشتراك في الحصريات',
                en: '🌟 Subscribe to exclusives'),
            description: language(
                ar: 'احصل على صلاحية الإستماع لحصريات ألحاني',
                en: 'Get access to Alhani\'s exclusives'),
            onClickedPackage: (package) async {
              final success = await PurchaseApi.purchasePackage(package);
              if(success){
                await usersRef
                    .doc(Constants.currentUserID)
                    .update({'exclusive_last_date': FieldValue.serverTimestamp()});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(language(
                      ar: 'تمت عملية الشراء بنجاح',
                      en: 'Purchase success')),
                ));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(language(
                      ar: 'لم تتم عملية الشراء',
                      en: 'Purchase Failed')),
                ));
              }
              Future.delayed(Duration(milliseconds: 1000), () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              });
            },
          );
        });
  }
}
