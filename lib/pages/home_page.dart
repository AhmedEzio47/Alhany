import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/category_model.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/pages/song_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/list_items/record_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import '../app_util.dart';
import 'singer_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  int _page = 0;
  bool _isPlaying = false;

  PageController _pageController;

  TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
                              //_isPlaying = false;
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
                            children: [
                              _songsPage(),
                              _melodiesPage(),
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
        //getSingers();
        getMelodies();
        getRecords();
        break;
      case 2:
        getFavourites();
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
              //   musicPlayer = MusicPlayer(
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
          SliverList(
            delegate: SliverChildListDelegate([
              MediaQuery.removePadding(
                  context: context, removeTop: true, child: recordListView())
            ]),
          ),
        ],
      ),
    );
  }

  _melodiesList() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListView.builder(
          primary: false,
          shrinkWrap: true,
          controller: _melodiesPageScrollController,
          itemCount: _melodies.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () async {
                setState(() {
                  musicPlayer = MusicPlayer(
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
                    melodyList: [_favourites[index]],
                    key: ValueKey(_favourites[index].id),
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
          )
        ],
      ),
    )));
  }
}
