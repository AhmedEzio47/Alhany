import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/pages/app_page.dart';
import 'package:Alhany/pages/welcome_page.dart';
import 'package:Alhany/services/auth.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/flip_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RootPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool emailVerified;

  AuthStatus _authStatus = AuthStatus.NOT_DETERMINED;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await authAssignment();
  }

  @override
  void initState() {
    getLanguage();
    super.initState();
  }

  getLanguage() async {
    String language = await AppUtil.getLanguage();
    if (language == null) {
      Constants.language = 'ar';
    } else {
      Constants.language = language;
    }
  }

  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(
        color: MyColors.primaryColor,
        alignment: Alignment.center,
        child: Center(
            child: FlipLoader(
                loaderBackground: Colors.white,
                iconColor: MyColors.primaryColor,
                icon: Icons.music_note,
                animationType: "full_flip")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
      case AuthStatus.NOT_LOGGED_IN:
        return WelcomePage();
      case AuthStatus.LOGGED_IN:
        return AppPage();
    }
    return null;
  }

  Future authAssignment() async {
    FirebaseUser user = await Auth().getCurrentUser();

    if (user?.uid != null && user.isEmailVerified && ((await DatabaseService.getUserWithId(user?.uid)).id != null)) {
      User loggedInUser = await DatabaseService.getUserWithId(user?.uid);

      User star = await DatabaseService.getUserWithId(Strings.starId);
      //AppUtil.createAppDirectory();

      setState(() {
        Constants.currentUser = loggedInUser;
        Constants.currentFirebaseUser = user;
        Constants.currentUserID = user?.uid;
        _authStatus = AuthStatus.LOGGED_IN;
        authStatus = AuthStatus.LOGGED_IN;
        Constants.startUser = star;

        Constants.isAdmin = (Constants.currentUserID == Strings.starId);
      });
    } else if (user?.uid != null && !(user.isEmailVerified)) {
      print('!(user.isEmailVerified) = ${!(user.isEmailVerified)}');
      setState(() {
        _authStatus = AuthStatus.NOT_LOGGED_IN;
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    } else {
      setState(() {
        _authStatus = AuthStatus.NOT_LOGGED_IN;
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    }
    print('authStatus = $_authStatus');
  }
}
