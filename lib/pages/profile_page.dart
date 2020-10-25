import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/auth.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:dubsmash/widgets/custom_modal.dart';
import 'package:dubsmash/widgets/custom_ovelay.dart';
import 'package:dubsmash/widgets/image_edit_bottom_sheet.dart';
import 'package:dubsmash/widgets/list_items/melody_item.dart';
import 'package:dubsmash/widgets/list_items/record_item.dart';
import 'package:dubsmash/widgets/flip_loader.dart';
import 'package:dubsmash/widgets/music_player.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key key, this.userId}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  bool _editing = false;

  TextEditingController _descriptionController = TextEditingController();

  TextEditingController _nameController = TextEditingController();

  User _user;

  TabController _tabController;
  int _page = 0;

  List<Record> _records = [];

  bool _isPlaying = false;

  var _tabs;

  bool isFollowing = false;

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
    _tabController =
        TabController(vsync: this, length: widget.userId == Constants.currentUserID ? 2 : 1, initialIndex: 0);

    widget.userId == Constants.currentUserID
        ? _tabs = [
            Tab(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: MyColors.darkPrimaryColor, width: 1)),
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
                    border: Border.all(color: MyColors.darkPrimaryColor, width: 1)),
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Favourites"),
                ),
              ),
            )
          ]
        : _tabs = [
            Tab(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: MyColors.darkPrimaryColor, width: 1)),
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Records"),
                ),
              ),
            )
          ];
  }

  @override
  void initState() {
    checkIfUserIsFollowed();
    configureTabs();
    getRecords();
    getUser();
    super.initState();
  }

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
              colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
              image: AssetImage(Strings.default_bg),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            alignment: Alignment.topCenter,
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 50,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        widget.userId != Constants.currentUserID
                            ? InkWell(
                                onTap: isFollowing
                                    ? () {
                                        unfollowUser();
                                      }
                                    : () {
                                        followUser();
                                      },
                                child: Container(
                                  margin: EdgeInsets.only(right: 15),
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: MyColors.accentColor,
                                  ),
                                  child: !isFollowing
                                      ? Icon(
                                          Icons.person_add,
                                          size: 25,
                                          color: Colors.white,
                                        )
                                      : Image.asset(Strings.person_remove, scale: 1.3),
                                ),
                              )
                            : Container(),
                        _editing
                            ? InkWell(
                                onTap: () async {
                                  _updateProfileImage();
                                },
                                child: CustomOverlay(
                                  child: _profileImage(),
                                  shape: BoxShape.circle,
                                  size: 150,
                                  icon: Icon(
                                    Icons.photo_camera,
                                    color: Colors.black87,
                                    size: 35,
                                  ),
                                ),
                              )
                            : _profileImage(),
                        widget.userId != Constants.currentUserID
                            ? InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushNamed('/conversation', arguments: {'other_uid': widget.userId});
                                },
                                child: Container(
                                    margin: EdgeInsets.only(left: 15),
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: MyColors.accentColor,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline,
                                      size: 23,
                                      color: Colors.white,
                                    )),
                              )
                            : Container(),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    _editing
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Text(
                            _user?.name ?? '',
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    _editing
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: TextField(
                              controller: _descriptionController,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          )
                        : Text(
                            _user?.description ?? '',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    widget.userId == Constants.currentUserID
                        ? RaisedButton(
                            color: MyColors.accentColor,
                            shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
                            onPressed: () async {
                              setState(() {
                                _editing = !_editing;
                              });
                              if (_editing) {
                                setState(() {
                                  _nameController.text = _user.name;
                                  _descriptionController.text = _user.description;
                                });
                              } else {
                                _saveEdits();
                              }
                            },
                            child: Text(_editing ? 'Save' : 'Edit Profile',
                                style: TextStyle(fontSize: 14, color: Colors.white)),
                          )
                        : Container(),
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
                        indicator:
                            BoxDecoration(borderRadius: BorderRadius.circular(50), color: MyColors.darkPrimaryColor),
                        tabs: _tabs),
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
      ),
    );
  }

  checkIfUserIsFollowed() async {
    if (this.widget.userId != Constants.currentUserID) {
      DocumentSnapshot followSnapshot = await firestore
          .collection('users')
          .document(Constants.currentUserID)
          .collection('following')
          .document(widget.userId)
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
    AppUtil.showToast('User unfollowed');
  }

  void followUser() async {
    AppUtil.showLoader(context);

    await DatabaseService.followUser(widget.userId);
    await checkIfUserIsFollowed();

    Navigator.of(context).pop();
    AppUtil.showToast('User followed');
  }

  Widget _currentPage() {
    switch (_page) {
      case 0:
        return Expanded(
          flex: 8,
          child: _records.length > 0
              ? ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        // if (musicPlayer != null) {
                        //   musicPlayer.stop();
                        // }
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
                  })
              : Center(
                  child: Text(
                    'User records are listed here',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
        break;
      case 1:
        getFavourites();
        return Expanded(
          flex: 8,
          child: _favourites.length > 0
              ? ListView.builder(
                  itemCount: _favourites.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        // if (musicPlayer != null) {
                        //   musicPlayer.stop();
                        // }
                        musicPlayer = MusicPlayer(
                          url: _favourites[index].audioUrl,
                          backColor: Colors.white.withOpacity(.4),
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
                    'Your favourites are listed here',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
        break;

      default:
        return Container();
    }
  }

  Future _saveEdits() async {
    await usersRef.document(Constants.currentUserID).updateData({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'search': searchList(_nameController.text)
    });
    User user = await DatabaseService.getUserWithId(Constants.currentUserID);
    setState(() {
      _user = user;
    });
  }

  Widget _profileImage() {
    return CachedImage(
      imageShape: BoxShape.circle,
      height: 150,
      width: 150,
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
      AppUtil.showToast('Nothing chosen');
      return;
    }
    AppUtil.showLoader(context);

    String url = await AppUtil.uploadFile(
        image, context, 'profile_images/${Constants.currentUserID}${path.extension(image.path)}');
    await usersRef.document(Constants.currentUserID).updateData({'profile_url': url});
    Navigator.of(context).pop();
    await getUser();
    setState(() {
      _editing = false;
    });
  }
}
