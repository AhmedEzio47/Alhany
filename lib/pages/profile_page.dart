import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/slide_image.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_ovelay.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:Alhany/widgets/image_edit_bottom_sheet.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/list_items/record_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key key, this.userId}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  bool _editing = false;

  TextEditingController _descriptionController = TextEditingController();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();

  User _user;

  TabController _tabController;
  int _page = 0;

  List<Record> _records = [];

  bool _isPlaying = false;

  var _tabs;

  bool isFollowing = false;

  List<SlideImage> _slideImages = [];
  getSlideImages() async {
    List<SlideImage> slideImages =
        await DatabaseService.getSlideImages('الصفحة الشخصية');
    setState(() {
      _slideImages = slideImages;
    });
  }

  getRecords() async {
    List<Record> records = await DatabaseService.getUserRecords(widget.userId);
    if (mounted) {
      setState(() {
        _records = records;
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

  getUser() async {
    User user = await DatabaseService.getUserWithId(widget.userId);
    setState(() {
      _user = user;
    });
  }

  configureTabs() {
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {});
    });

    _tabs = [
      Tab(
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: MyColors.darkPrimaryColor, width: 1)),
          child: Align(
            alignment: Alignment.center,
            child: Text(language(en: "Records", ar: 'التسجيلات'),
                style: TextStyle(
                  fontSize: 14,
                )),
          ),
        ),
      ),
      Tab(
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: MyColors.textLightColor, width: 1)),
          child: Align(
            alignment: Alignment.center,
            child: Text(language(en: "Favourites", ar: 'المفضلات'),
                style: TextStyle(
                  fontSize: 14,
                )),
          ),
        ),
      )
    ];
  }

  LinkedScrollControllerGroup _controllers;
  ScrollController _recordsScrollController;
  ScrollController _favouritesScrollController;
  ScrollController _mainScrollController;

  @override
  void initState() {
    getSlideImages();
    checkIfUserIsFollowed();
    configureTabs();
    getRecords();
    getUser();
    _controllers = LinkedScrollControllerGroup();
    _recordsScrollController = _controllers.addAndGet();
    _favouritesScrollController = _controllers.addAndGet();
    _mainScrollController = _controllers.addAndGet();
    super.initState();
  }

  @override
  void dispose() {
    _recordsScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        drawer: BuildDrawer(),
        body: GestureDetector(
          onTap: () {
            // if (musicPlayer != null) {
            //   musicPlayer.stop();
            // }
            setState(() {
              _isPlaying = false;
            });
          },
          child: Container(
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
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: _user?.id != Constants.currentUserID
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
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
                              child: _user?.id != Constants.currentUserID
                                  ? Builder(
                                      builder: (context) => InkWell(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Icon(
                                          Icons.arrow_back,
                                          color: MyColors.accentColor,
                                        ),
                                      ),
                                    )
                                  : Builder(
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
                        Container(
                          width: _user?.id != Constants.currentUserID ? 35 : 0,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    authStatus == AuthStatus.NOT_LOGGED_IN &&
                            widget.userId == null
                        ? Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height / 2 -
                                    70),
                            child: Text(
                              language(
                                  en: 'Please log in to see page content',
                                  ar: 'من فضلك قم بتسجيل الدخول لترى محتوى الصفحة'),
                              style: TextStyle(color: MyColors.textLightColor),
                            ),
                          )
                        : Expanded(
                            child: CustomScrollView(
                                controller: _mainScrollController,
                                slivers: [
                                  SliverList(
                                    delegate: SliverChildListDelegate([
                                      _slideImages.length > 0
                                          ? CarouselSlider.builder(
                                              options: CarouselOptions(
                                                viewportFraction: 1,
                                                height: 200.0,
                                                autoPlay: true,
                                                autoPlayInterval:
                                                    Duration(seconds: 3),
                                                enlargeCenterPage: true,
                                              ),
                                              itemCount: _slideImages.length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                          int index) =>
                                                      CachedImage(
                                                imageUrl:
                                                    _slideImages[index]?.url,
                                                height: 200,
                                                imageShape: BoxShape.rectangle,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                defaultAssetImage:
                                                    Strings.default_cover_image,
                                              ),
                                            )
                                          : Container(),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: _editing
                                                ? InkWell(
                                                    onTap: () async {
                                                      _updateProfileImage();
                                                    },
                                                    child: CustomOverlay(
                                                      child: _profileImage(),
                                                      shape: BoxShape.circle,
                                                      size: 60,
                                                      icon: Icon(
                                                        Icons.photo_camera,
                                                        color: Colors.black87,
                                                        size: 25,
                                                      ),
                                                    ),
                                                  )
                                                : _profileImage(),
                                          ),
                                          widget.userId !=
                                                  Constants.currentUserID
                                              ? Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: isFollowing
                                                          ? () {
                                                              AppUtil.executeFunctionIfLoggedIn(
                                                                  context,
                                                                  () =>
                                                                      unfollowUser());
                                                            }
                                                          : () {
                                                              AppUtil.executeFunctionIfLoggedIn(
                                                                  context,
                                                                  () =>
                                                                      followUser());
                                                            },
                                                      child: Container(
                                                        margin: EdgeInsets.only(
                                                            right: 15),
                                                        height: 40,
                                                        width: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: MyColors
                                                              .accentColor,
                                                        ),
                                                        child: !isFollowing
                                                            ? Icon(
                                                                Icons
                                                                    .person_add,
                                                                size: 25,
                                                                color: MyColors
                                                                    .iconLightColor,
                                                              )
                                                            : Image.asset(
                                                                Strings
                                                                    .person_remove,
                                                                scale: 1.3),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        AppUtil
                                                            .executeFunctionIfLoggedIn(
                                                                context, () {
                                                          Navigator.of(context)
                                                              .pushNamed(
                                                                  '/conversation',
                                                                  arguments: {
                                                                'other_uid':
                                                                    widget
                                                                        .userId
                                                              });
                                                        });
                                                      },
                                                      child: Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left: 15),
                                                          height: 40,
                                                          width: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: MyColors
                                                                .accentColor,
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .chat_bubble_outline,
                                                            size: 23,
                                                            color: MyColors
                                                                .iconLightColor,
                                                          )),
                                                    )
                                                  ],
                                                )
                                              : Container(
                                                  child: RaisedButton(
                                                    color: MyColors.accentColor,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            new BorderRadius
                                                                    .circular(
                                                                20.0)),
                                                    onPressed: () async {
                                                      setState(() {
                                                        _editing = !_editing;
                                                      });
                                                      if (_editing) {
                                                        setState(() {
                                                          _nameController.text =
                                                              _user.name;
                                                          _usernameController
                                                                  .text =
                                                              _user.username;
                                                          _descriptionController
                                                                  .text =
                                                              _user.description;
                                                        });
                                                      } else {
                                                        _saveEdits();
                                                      }
                                                    },
                                                    child: Text(
                                                        _editing
                                                            ? language(
                                                                en: 'Save',
                                                                ar: 'حفظ')
                                                            : language(
                                                                en:
                                                                    'Edit Profile',
                                                                ar: 'تعديل'),
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: MyColors
                                                                .textDarkColor)),
                                                  ),
                                                ),
                                          // widget.userId != Constants.currentUserID
                                          //     ? InkWell(
                                          //         onTap: () {
                                          //           Navigator.of(context)
                                          //               .pushNamed('/conversation', arguments: {'other_uid': widget.userId});
                                          //         },
                                          //         child: Container(
                                          //             margin: EdgeInsets.only(left: 15),
                                          //             height: 40,
                                          //             width: 40,
                                          //             decoration: BoxDecoration(
                                          //               shape: BoxShape.circle,
                                          //               color: MyColors.accentColor,
                                          //             ),
                                          //             child: Icon(
                                          //               Icons.chat_bubble_outline,
                                          //               size: 23,
                                          //               color: Colors.white,
                                          //             )),
                                          //       )
                                          //     : Container(),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: _editing
                                                ? Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        height: 30,
                                                        width: 120,
                                                        child: TextField(
                                                          controller:
                                                              _nameController,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 20,
                                                              color: MyColors
                                                                  .textLightColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      Container(
                                                        height: 30,
                                                        width: 120,
                                                        child: TextField(
                                                          controller:
                                                              _usernameController,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: MyColors
                                                                  .textLightColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        _user?.name ?? '',
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            color: MyColors
                                                                .textLightColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Text(
                                                        '@${_user?.username ?? ''}',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: MyColors
                                                                .textInactiveColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ],
                                      ),

                                      // SizedBox(
                                      //   height: 10,
                                      // ),
                                      // _editing
                                      //     ? Padding(
                                      //         padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      //         child: TextField(
                                      //           controller: _descriptionController,
                                      //           textAlign: TextAlign.center,
                                      //           style: TextStyle(fontSize: 16, color: Colors.white),
                                      //         ),
                                      //       )
                                      //     : Padding(
                                      //         padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      //         child: Text(
                                      //           _user?.description ?? '',
                                      //           textAlign: TextAlign.center,
                                      //           style: TextStyle(fontSize: 16, color: Colors.white),
                                      //         ),
                                      //       ),
                                      // SizedBox(
                                      //   height: 10,
                                      // ),
                                      // widget.userId == Constants.currentUserID
                                      //     ? Container(
                                      //         margin: EdgeInsets.symmetric(horizontal: 145),
                                      //         child: RaisedButton(
                                      //           color: MyColors.accentColor,
                                      //           shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
                                      //           onPressed: () async {
                                      //             setState(() {
                                      //               _editing = !_editing;
                                      //             });
                                      //             if (_editing) {
                                      //               setState(() {
                                      //                 _nameController.text = _user.name;
                                      //                 _usernameController.text = _user.username;
                                      //                 _descriptionController.text = _user.description;
                                      //               });
                                      //             } else {
                                      //               _saveEdits();
                                      //             }
                                      //           },
                                      //           child: Text(
                                      //               _editing
                                      //                   ? language(en: 'Save', ar: 'حفظ')
                                      //                   : language(en: 'Edit Profile', ar: 'تعديل'),
                                      //               style: TextStyle(fontSize: 14, color: Colors.white)),
                                      //         ),
                                      //       )
                                      //     : Container(),
                                      SizedBox(
                                        height: 10,
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
                                              print('page=${_page}');
                                            });
                                          },
                                          controller: _tabController,
                                          unselectedLabelColor:
                                              MyColors.textLightColor,
                                          indicatorColor: Colors.grey,
                                          labelColor: MyColors.primaryColor,
                                          indicatorSize:
                                              TabBarIndicatorSize.label,
                                          indicator: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              color: MyColors.darkPrimaryColor),
                                          tabs: _tabs),
                                      MediaQuery.removePadding(
                                          context: context,
                                          removeTop: true,
                                          child: _currentPage())
                                    ]),
                                  ),
                                ]),
                          ),
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
        floatingActionButton: _page == 1
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

  checkIfUserIsFollowed() async {
    if (this.widget.userId != Constants.currentUserID) {
      DocumentSnapshot followSnapshot = await firestore
          .collection('users')
          .doc(Constants.currentUserID)
          .collection('following')
          .doc(widget.userId)
          .get();

      setState(() {
        isFollowing = followSnapshot.exists;
      });
    }
  }

  void unfollowUser() async {
    AppUtil.showLoader(context);

    await DatabaseService.unfollowUser(widget.userId);

    await checkIfUserIsFollowed();

    Navigator.of(context).pop();
    AppUtil.showToast(language(en: 'User unfollowed', ar: 'تم إلغاء المتابعة'));
  }

  void followUser() async {
    AppUtil.showLoader(context);

    await DatabaseService.followUser(widget.userId);
    await checkIfUserIsFollowed();

    Navigator.of(context).pop();
    AppUtil.showToast(language(en: 'User followed', ar: 'تمت المتابعة'));
  }

  Widget _currentPage() {
    switch (_page) {
      case 0:
        return StreamBuilder<QuerySnapshot>(
          stream:
              recordsRef.where('singer_id', isEqualTo: _user?.id)?.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              default:
                return ListView.builder(
                    controller: _recordsScrollController,
                    itemCount: _records.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          // if (musicPlayer != null) {
                          //   musicPlayer.stop();
                          // }
                          // musicPlayer = MusicPlayer(
                          //   url: _records[index].url,
                          //   backColor: Colors.white.withOpacity(.4),
                          // );
                          // setState(() {
                          //   _isPlaying = true;
                          // });
                        },
                        child: RecordItem(
                          record: _records[index],
                          key: UniqueKey(),
                        ),
                      );
                    });
            }
          },
        );
      case 1:
        getFavourites();
        return _favourites.length > 0
            ? ListView.builder(
                controller: _favouritesScrollController,
                shrinkWrap: true,
                itemCount: _favourites.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      // if (musicPlayer != null) {
                      //   musicPlayer.stop();
                      // }
                      musicPlayer = MusicPlayer(
                        key: ValueKey(_favourites[index].id),
                        melodyList: [_favourites[index]],
                        title: _favourites[index].name,
                        initialDuration: _favourites[index].duration,
                        backColor: MyColors.lightPrimaryColor.withOpacity(.8),
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
                  style: TextStyle(color: MyColors.textLightColor),
                ),
              );
        break;

      default:
        return Container();
    }
  }

  Future _saveEdits() async {
    String validUsername = validateUsername(_usernameController.text);
    final taken = await isUsernameTaken(_usernameController.text);
    bool isValidUsername = true;

    if (taken) {
      // username exists
      if (_usernameController.text != _user.username) {
        AppUtil.showToast(
            '${_usernameController.text} is already in use. Please choose a different username.');
      }
      isValidUsername = false;
    }
    if (validUsername != null) {
      if (_usernameController.text != _user.username) {
        AppUtil.showToast(
            language(en: 'Invalid Username!', ar: 'اسم المستخدم غير مسموح'));
      }
      isValidUsername = false;
    }

    List<String> search = searchList(_nameController.text);
    search.addAll(searchList(_usernameController.text));

    await usersRef.doc(Constants.currentUserID).update({
      'username': isValidUsername ? _usernameController.text : _user.username,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'search': search
    });

    User user = await DatabaseService.getUserWithId(Constants.currentUserID);
    setState(() {
      _user = user;
    });
  }

  Widget _profileImage() {
    return CachedImage(
      imageShape: BoxShape.circle,
      height: 60,
      width: 60,
      imageUrl: _user?.profileImageUrl,
      defaultAssetImage: Strings.default_profile_image,
    );
  }

  Future _updateProfileImage() async {
    ImageEditBottomSheet bottomSheet = ImageEditBottomSheet();
    await bottomSheet.openBottomSheet(context);

    File image;
    if (bottomSheet.source == ImageSource.gallery) {
      image = await AppUtil.pickImageFromGallery();
    } else if (bottomSheet.source == ImageSource.camera) {
      image = await AppUtil.takePhoto();
    } else {
      AppUtil.showToast(language(en: 'Nothing chosen', ar: 'لم تختر شيئا'));
      return;
    }
    AppUtil.showLoader(context);

    String url = await AppUtil().uploadFile(image, context,
        'profile_images/${Constants.currentUserID}${path.extension(image.path)}');
    await usersRef.doc(Constants.currentUserID).update({'profile_url': url});
    Navigator.of(context).pop();
    await getUser();
    setState(() {
      _editing = false;
    });
  }

  String validateUsername(String value) {
    String errorMsgUsername;
    String pattern =
        r'^(?=.{4,20}$)(?![_.])(?!.*[_.]{2})[a-zA-Z0-9._]+(?<![_.])$';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      AppUtil.showToast(
        language(en: "Username is Required", ar: 'اسم المستخدم مطلوب'),
      );
      setState(() {
        errorMsgUsername = "Username is Required";
      });
    } else if (!regExp.hasMatch(value)) {
      //AppUtil().showToast("Invalid Username");
      setState(() {
        errorMsgUsername = "Invalid Username";
      });
      return errorMsgUsername;
    } else {
      setState(() {
        errorMsgUsername = null;
      });
    }
    return errorMsgUsername;
  }

  Future<bool> isUsernameTaken(String username) async {
    final QuerySnapshot result =
        await usersRef.where('username', isEqualTo: username).limit(1).get();
    return result.docs.isNotEmpty;
  }

  Future<bool> _onBackPressed() {
    /// Navigate back to home page
    if (widget.userId == Constants.currentUserID)
      Navigator.of(context).pushReplacementNamed('/app-page');
    else
      Navigator.of(context).pop();
  }
}
