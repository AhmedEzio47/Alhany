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
import 'package:Alhany/widgets/list_items/news_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class StarPage extends StatefulWidget {
  @override
  _StarPageState createState() => _StarPageState();
}

class _StarPageState extends State<StarPage>
    with SingleTickerProviderStateMixin {
  ScrollController _exclusivesScrollController = ScrollController();
  TabController _tabController;
  int _page = 0;
  Timestamp lastVisiblePostSnapShot;

  Color _searchColor = Colors.grey.shade300;

  TextEditingController _searchController = TextEditingController();

  List<Melody> _exclusives = [];
  List<Melody> _filteredexclusives = [];

  ScrollController _scrollController = ScrollController();

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

  List<SlideImage> _slideImages = [];
  getSlideImages() async {
    List<SlideImage> slideImages =
        await DatabaseService.getSlideImages('صفحة الفنان');
    setState(() {
      _slideImages = slideImages;
    });
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

  searchexclusives(String text) async {
    List<Melody> filteredexclusives =
        await DatabaseService.searchExclusives(text);
    if (mounted) {
      setState(() {
        _filteredexclusives = filteredexclusives;
      });
    }
  }

  RemoteConfig _remoteConfig;

  @override
  void initState() {
    super.initState();
    fetchExclusiveFee();
    getSlideImages();
    getExclusives();
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
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
                                      text:
                                          language(en: 'Exclusive', ar: 'حصري'),
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
        return Constants.currentUser.exclusiveLastDate == null
            ? Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Column(
                  children: [
                    Text(
                      language(
                          ar: 'من فضلك قم بالاشتراك لكي تستمع للحصريات',
                          en: 'Please subscribe in order to listen to exclusives'),
                      style: TextStyle(color: MyColors.textLightColor),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    MaterialButton(
                      color: MyColors.accentColor,
                      onPressed: subscribe,
                      child: Text(language(ar: 'اشترك', en: 'Subscribe')),
                    )
                  ],
                ),
              )
            : DateTime.now().difference(
                        Constants.currentUser.exclusiveLastDate.toDate()) >
                    Duration(days: 30)
                ? Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Text(
                          language(
                              ar: 'من فضلك قم بتجديد الاشتراك لكي تستمع بالحصريات',
                              en: 'Please renew subscription in order to listen to exclusives'),
                          style: TextStyle(color: MyColors.textLightColor),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        MaterialButton(
                          color: MyColors.accentColor,
                          onPressed: subscribe,
                          child: Text(language(ar: 'تجديد', en: 'Renew')),
                        )
                      ],
                    ),
                  )
                : _isSearching
                    ? GridView.builder(
                        shrinkWrap: true,
                        primary: false,
                        controller: _exclusivesScrollController,
                        itemCount: _filteredexclusives.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: .8,
                          crossAxisCount: 2,
                        ),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () async {
                              setState(() {
                                musicPlayer = MusicPlayer(
                                  checkPrice: false,
                                  key: ValueKey(_filteredexclusives[index].id),
                                  backColor: MyColors.lightPrimaryColor
                                      .withOpacity(.8),
                                  title: _filteredexclusives[index].name,
                                  btnSize: 30,
                                  initialDuration:
                                      _filteredexclusives[index].duration,
                                  melodyList: [_filteredexclusives[index]],
                                  isRecordBtnVisible: true,
                                );
                                _isPlaying = true;
                              });
                            },
                            child: Container(
                              key: ValueKey('melody_item'),
                              child: Column(
                                children: [
                                  CachedImage(
                                    imageUrl:
                                        _filteredexclusives[index].imageUrl,
                                    width: 200,
                                    height: 200,
                                    defaultAssetImage:
                                        Strings.default_melody_image,
                                    imageShape: BoxShape.rectangle,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    _exclusives[index].name,
                                    style: TextStyle(
                                        color: MyColors.textLightColor),
                                  )
                                ],
                              ),
                            ),
                          );
                        })
                    : GridView.builder(
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
                            onTap: () async {
                              setState(() {
                                musicPlayer = MusicPlayer(
                                  checkPrice: false,
                                  key: ValueKey(_exclusives[index].id),
                                  backColor: MyColors.lightPrimaryColor
                                      .withOpacity(.8),
                                  title: _exclusives[index].name,
                                  btnSize: 30,
                                  initialDuration: _exclusives[index].duration,
                                  melodyList: [_exclusives[index]],
                                  isRecordBtnVisible: true,
                                );
                                _isPlaying = true;
                              });
                            },
                            child: Container(
                              key: ValueKey('melody_item'),
                              child: Column(
                                children: [
                                  CachedImage(
                                    imageUrl: _exclusives[index].imageUrl,
                                    width: 200,
                                    height: 200,
                                    defaultAssetImage:
                                        Strings.default_melody_image,
                                    imageShape: BoxShape.rectangle,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    _exclusives[index].name,
                                    style: TextStyle(
                                        color: MyColors.textLightColor),
                                  )
                                ],
                              ),
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
                      await searchexclusives(text.toLowerCase());
                    },
                    decoration: InputDecoration(
                        fillColor: _searchColor,
                        focusColor: _searchColor,
                        hoverColor: _searchColor,
                        hintText: 'Search exclusives...',
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
                            _filteredexclusives = [];
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

  Future setupRemoteConfig() async {
    await Firebase.initializeApp();
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    // Allow a fetch every millisecond. Default is 12 hours.
    remoteConfig
        .setConfigSettings(RemoteConfigSettings(minimumFetchIntervalMillis: 1));
    remoteConfig.setDefaults(<String, dynamic>{
      'welcome': 'default welcome',
      'hello': 'default hello',
    });
    this._remoteConfig = remoteConfig;
  }

  Future subscribe() async {
    String exFee = await fetchExclusiveFee();
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
  }

  Future<String> fetchExclusiveFee() async {
    await setupRemoteConfig();
    await _remoteConfig.fetch(expiration: const Duration(seconds: 0));
    await _remoteConfig.activateFetched();
    String exclusiveFee = _remoteConfig.getString('exclusives_fee');
    return exclusiveFee;
  }
}
