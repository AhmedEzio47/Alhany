import 'dart:io';

import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:dubsmash/widgets/custom_ovelay.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key key, this.userId}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _editing = false;

  TextEditingController _descriptionController = TextEditingController();

  TextEditingController _nameController = TextEditingController();

  User _user;

  getUser() async {
    User user = await DatabaseService.getUserWithId(widget.userId);
    setState(() {
      _user = user;
    });
  }

  @override
  void initState() {
    getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Container(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                ),
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
                SizedBox(
                  height: 20,
                ),
                _editing
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : Text(
                        _user?.name ?? '',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(20.0)),
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
                            style:
                                TextStyle(fontSize: 14, color: Colors.white)),
                      )
                    : Container()
              ],
            ),
          ),
        ),
      ),
    );
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
    File image = await AppUtil.chooseImage();
    String url = await AppUtil.uploadFile(image, context,
        'profile_images/${Constants.currentUserID}${path.extension(image.path)}');
    await usersRef
        .document(Constants.currentUserID)
        .updateData({'profile_url': url});
    setState(() {
      _editing = false;
    });
  }
}
