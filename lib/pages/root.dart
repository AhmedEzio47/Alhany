import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/user_model.dart' as user_model;
import 'package:Alhany/pages/app_page.dart';
import 'package:Alhany/services/auth.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/flip_loader.dart';
import 'package:audio_service/audio_service.dart';
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
    getStarUser();
    super.initState();
  }

  getStarUser() async {
    user_model.User star = await DatabaseService.getUserWithId(Strings.starId);
    Constants.starUser = star;
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
            //
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
        //return WelcomePage();
        return AudioServiceWidget(child: AppPage());
      case AuthStatus.LOGGED_IN:
        return AudioServiceWidget(child: AppPage());
    }
    return null;
  }

  Future authAssignment() async {
    User user = await Auth().getCurrentUser();

    if (user?.uid != null &&
        ((await DatabaseService.getUserWithId(user?.uid)).id != null)) {
      AppUtil.setUserVariablesByFirebaseUser(user);
      setState(() {
        _authStatus = AuthStatus.LOGGED_IN;
      });
    } else if (user?.uid != null && !(user.emailVerified)) {
      print('!(user.isEmailVerified) = ${!(user.emailVerified)}');
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
