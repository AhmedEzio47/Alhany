import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/slide_image.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/list_items/news_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StarPage extends StatefulWidget {
  @override
  _StarPageState createState() => _StarPageState();
}

class _StarPageState extends State<StarPage>
    with SingleTickerProviderStateMixin {
  ScrollController _melodiesScrollController = ScrollController();
  TabController _tabController;
  int _page = 0;
  Timestamp lastVisiblePostSnapShot;

  Color _searchColor = Colors.grey.shade300;

  TextEditingController _searchController = TextEditingController();

  List<Melody> _melodies = [];
  List<Melody> _filteredMelodies = [];

  ScrollController _scrollController = ScrollController();

  getMelodies() async {
    List<Melody> melodies = await DatabaseService.getStarMelodies();
    if (mounted) {
      setState(() {
        _melodies = melodies;
        if (_melodies.length > 0)
          this.lastVisiblePostSnapShot = melodies.last.timestamp;
      });
    }
  }

  List<SlideImage> _slideImages = [];
  getSlideImages() async {
    List<SlideImage> slideImages =
        await DatabaseService.getSlideImages('صفحة الفنان');
    setState(() {
      _slideImages = slideImages;
    });
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

  searchMelodies(String text) async {
    List<Melody> filteredMelodies = await DatabaseService.searchMelodies(text);
    if (mounted) {
      setState(() {
        _filteredMelodies = filteredMelodies;
      });
    }
  }

  @override
  void initState() {
    getSlideImages();
    getMelodies();
    super.initState();
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    _melodiesScrollController
      ..addListener(() {
        if (_melodiesScrollController.offset >=
                _melodiesScrollController.position.maxScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print('reached the bottom');
          if (!_isSearching) nextMelodies();
        } else if (_melodiesScrollController.offset <=
                _melodiesScrollController.position.minScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
  }

  bool _isPlaying = false;
  bool _isSearching = false;

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
                    colorFilter: new ColorFilter.mode(
                        Colors.black.withOpacity(0.1), BlendMode.dstATop),
                    image: AssetImage(Strings.default_bg),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  children: [
                    Align(
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
                      ),
                      alignment: Alignment.topCenter,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              _slideImages.length > 0
                                  ? CarouselSlider.builder(
                                      options: CarouselOptions(
                                        viewportFraction: 1,
                                        height: 200.0,
                                        autoPlay: true,
                                        autoPlayInterval: Duration(seconds: 3),
                                        enlargeCenterPage: true,
                                      ),
                                      itemCount: _slideImages.length,
                                      itemBuilder:
                                          (BuildContext context, int index) =>
                                              CachedImage(
                                        imageUrl: _slideImages[index]?.url,
                                        height: 200,
                                        imageShape: BoxShape.rectangle,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        defaultAssetImage:
                                            Strings.default_cover_image,
                                      ),
                                    )
                                  : Container(),
                              SizedBox(
                                height: 10,
                              ),
                              Constants.isAdmin ?? false
                                  ? Center(
                                      child: InkWell(
                                          onTap: () => Navigator.of(context)
                                              .pushNamed('/slide-images'),
                                          child: Text(
                                            'Edit Slide show images',
                                            style: TextStyle(
                                                color: MyColors.textLightColor,
                                                decoration:
                                                    TextDecoration.underline),
                                          )),
                                    )
                                  : Container(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: CachedImage(
                                      width: 60,
                                      height: 60,
                                      imageShape: BoxShape.circle,
                                      imageUrl:
                                          Constants.starUser?.profileImageUrl,
                                      defaultAssetImage:
                                          Strings.default_profile_image,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      Constants.starUser?.name ?? '',
                                      style: TextStyle(
                                          color: MyColors.textLightColor,
                                          fontSize: 16),
                                    ),
                                  )
                                ],
                              ),
                            ]),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate([
                              TabBar(
                                  onTap: (index) {
                                    setState(() {
                                      //_isPlaying = false;
                                      _page = index;
                                    });
                                  },
                                  labelColor: MyColors.accentColor,
                                  unselectedLabelColor: Colors.grey,
                                  controller: _tabController,
                                  tabs: [
                                    Tab(
                                      text: language(
                                          en: 'Melodies', ar: 'آخر الأعمال'),
                                    ),
                                    Tab(
                                      text: language(
                                          en: 'News', ar: 'آخر الأخبار'),
                                    ),
                                  ]),
                              MediaQuery.removePadding(
                                  context: context,
                                  removeTop: true,
                                  child: _currentPage())
                            ]),
                          ),
                        ],
                      ),
                    ),
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
              _page == 0 ? _searchBar() : Container(),
            ],
          ),
        ),
        floatingActionButton: Constants.isAdmin ?? false
            ? FloatingActionButton(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.add_circle,
                  color: MyColors.primaryColor,
                ),
                onPressed: () async {
                  AppUtil.showAlertDialog(
                      context: context,
                      message: language(
                          en: 'What do you want to upload?',
                          ar: 'ما الذي تريد رفعه؟'),
                      firstBtnText: language(en: 'Melody', ar: 'لحن'),
                      firstFunc: () async {
                        Navigator.of(context).pop();
                        AppUtil.showAlertDialog(
                            context: context,
                            message: language(
                                en: 'Single level or multi-level melody?',
                                ar: 'لحن مستوى واحد أم متعدد المستويات؟'),
                            firstBtnText: language(en: 'Single', ar: 'أحادي'),
                            firstFunc: () async {
                              Navigator.of(context).pop();
                              Navigator.of(context)
                                  .pushNamed('/upload-single-level-melody');
                            },
                            secondBtnText: language(
                                en: 'Multi level', ar: 'متعدد المستويات'),
                            secondFunc: () async {
                              Navigator.of(context).pop();
                              Navigator.of(context)
                                  .pushNamed('/upload-multi-level-melody');
                            });
                      },
                      thirdBtnText: language(en: 'News', ar: 'خبر'),
                      thirdFunc: () =>
                          Navigator.of(context).pushNamed('/upload-news'),
                      secondBtnText: language(en: 'Song', ar: 'أغنية'),
                      secondFunc: () async {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/upload-songs');
                      });
                },
              )
            : null,
      ),
    );
  }

  List<News> _news = [];
  getNews() async {
    List<News> news = await DatabaseService.getNews();
    if (mounted) {
      setState(() {
        _news = news;
      });
    }
  }

  Widget _currentPage() {
    switch (_page) {
      case 1:
        getNews();
        return ListView.builder(
            primary: false,
            shrinkWrap: true,
            itemCount: _news.length,
            itemBuilder: (context, index) {
              return NewsItem(
                news: _news[index],
              );
            });
      case 0:
        return _isSearching
            ? ListView.builder(
                shrinkWrap: true,
                primary: false,
                controller: _melodiesScrollController,
                itemCount: _filteredMelodies.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      setState(() {
                        musicPlayer = MusicPlayer(
                          key: ValueKey(_filteredMelodies[index].id),
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _filteredMelodies[index].name,
                          btnSize: 30,
                          initialDuration: _filteredMelodies[index].duration,
                          melodyList: [_filteredMelodies[index]],
                          isRecordBtnVisible: true,
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
                primary: false,
                controller: _melodiesScrollController,
                itemCount: _melodies.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      setState(() {
                        musicPlayer = MusicPlayer(
                          key: ValueKey(_melodies[index].id),
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _melodies[index].name,
                          btnSize: 30,
                          initialDuration: _melodies[index].duration,
                          melodyList: [_melodies[index]],
                          isRecordBtnVisible: true,
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
    }
  }

  Widget _searchBar() {
    return Positioned.fill(
        child: Align(
      child: Padding(
        padding: const EdgeInsets.only(top: 25, left: 40),
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
                      await searchMelodies(text.toLowerCase());
                    },
                    decoration: InputDecoration(
                        fillColor: _searchColor,
                        focusColor: _searchColor,
                        hoverColor: _searchColor,
                        hintText: 'Search melodies...',
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

  Future<bool> _onBackPressed() {
    /// Navigate back to home page
    Navigator.of(context).pushReplacementNamed('/app-page');
  }
}
