import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/list_items/news_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StarPage extends StatefulWidget {
  @override
  _StarPageState createState() => _StarPageState();
}

class _StarPageState extends State<StarPage> with TickerProviderStateMixin {
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

  @override
  void initState() {
    getMelodies();
    super.initState();
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
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
  }

  bool _isPlaying = false;
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
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
                    colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                    image: AssetImage(Strings.default_bg),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      child: Container(
                        margin: const EdgeInsets.only(top: 35),
                        height: 40,
                        width: 150,
                        child: Image.asset(
                          Strings.app_bar,
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
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 155),
                                child: CachedImage(
                                  width: 100,
                                  height: 100,
                                  imageShape: BoxShape.circle,
                                  imageUrl: Constants.startUser?.profileImageUrl,
                                  defaultAssetImage: Strings.default_profile_image,
                                ),
                              ),
                              SizedBox(
                                height: 30,
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
                                      text: language(en: 'Melodies', ar: 'آخر الأعمال'),
                                    ),
                                    Tab(
                                      text: language(en: 'News', ar: 'آخر الأخبار'),
                                    ),
                                  ]),
                              _currentPage()
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
                      thirdBtnText: language(en: 'News', ar: 'خبر'),
                      thirdFunc: () => Navigator.of(context).pushNamed('/upload-news'),
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
                          url: _filteredMelodies[index].audioUrl,
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _filteredMelodies[index].name,
                          btnSize: 30,
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
                primary: false,
                controller: _melodiesScrollController,
                itemCount: _melodies.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      setState(() {
                        musicPlayer = MusicPlayer(
                          key: ValueKey(_melodies[index].id),
                          url: _melodies[index].audioUrl ?? _melodies[index].levelUrls.values.elementAt(0),
                          backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                          title: _melodies[index].name,
                          btnSize: 30,
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
    }
  }

  Widget _searchBar() {
    return Positioned.fill(
        child: Align(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 40),
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
