import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/pages/app_page.dart';
import 'package:dubsmash/pages/welcome_page.dart';
import 'package:dubsmash/services/auth.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RootPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool emailVerified;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await authAssignment();
  }

  @override
  void initState() {
    authAssignment();
    super.initState();
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
    switch (authStatus) {
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
    if (user?.uid != null &&
        user.isEmailVerified &&
        ((await DatabaseService.getUserWithId(user?.uid)).id != null)) {
      User loggedInUser = await DatabaseService.getUserWithId(user?.uid);
      setState(() {
        Constants.currentUser = loggedInUser;
        Constants.currentFirebaseUser = user;
        Constants.currentUserID = user?.uid;
        authStatus = AuthStatus.LOGGED_IN;
      });
    } else if (user?.uid != null && !(user.isEmailVerified)) {
      print('!(user.isEmailVerified) = ${!(user.isEmailVerified)}');
      //await showVerifyEmailSentDialog(context);
      setState(() {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    } else {
      setState(() {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    }
    print('authStatus = $authStatus');
  }
}
