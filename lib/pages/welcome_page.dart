import 'dart:io';

import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/user_model.dart' as user_model;
import 'package:Alhany/services/auth.dart';
import 'package:Alhany/services/auth_provider.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../app_util.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => new _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String _errorMsgEmail = '';

  final FocusNode myFocusNodePassword = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeName = FocusNode();
  final FocusNode myFocusNodeConfirmPassword = FocusNode();

  int _currentPage;
  String _userId = "";

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  Color _prefixIconColor = Colors.grey.shade500;

  @override
  void initState() {
    super.initState();
  }

  Widget HomePage() {
    return new Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: MyColors.primaryColor,
        image: DecorationImage(
          colorFilter: new ColorFilter.mode(
              Colors.black.withOpacity(0.1), BlendMode.dstATop),
          image: AssetImage('assets/images/splash.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 100.0),
              child: Container(
                color: Colors.black.withOpacity(.3),
                height: 170,
                width: MediaQuery.of(context).size.width,
                child: Center(
                    child: Image.asset(
                  Strings.app_icon,
                  scale: 1.2,
                )),
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin:
                  const EdgeInsets.only(left: 30.0, right: 30.0, top: 110.0),
              alignment: Alignment.center,
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new FlatButton(
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0)),
                      color: Colors.white,
                      onPressed: () => _gotoLogin(),
                      child: new Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 20.0,
                        ),
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Expanded(
                              child: Text(
                                language(en: "LOGIN", ar: 'تسجيل الدخول'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: MyColors.primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 30.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: MyColors.accentColor,
                  borderRadius: BorderRadius.circular(30.0)),
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new OutlineButton(
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0)),
                      color: MyColors.darkPrimaryColor,
                      highlightedBorderColor: Colors.white,
                      onPressed: () => _gotoSignUp(),
                      child: new Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 20.0,
                        ),
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Expanded(
                              child: Text(
                                language(en: "SIGN UP", ar: 'تسجيل'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: MyColors.textDarkColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Widget LoginPage() {
    return new Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          colorFilter: new ColorFilter.mode(
              Colors.black.withOpacity(0.1), BlendMode.dstATop),
          image: AssetImage('assets/images/splash.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: new Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      height: 220,
                      width: 220,
                      child: Center(
                          child: Image.asset(
                        Strings.app_icon,
                        scale: 1.5,
                      )),
                    ),
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 40.0, right: 40.0, top: 0.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MyColors.primaryColor,
                          width: 0.5,
                          style: BorderStyle.solid),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        child: TextField(
                          controller: _emailController,
                          obscureText: false,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: _prefixIconColor,
                            ),
                            border: InputBorder.none,
                            hintText: 'johndoe@example.com',
                            hintStyle:
                                TextStyle(color: MyColors.textInactiveColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MyColors.primaryColor,
                          width: 0.5,
                          style: BorderStyle.solid),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: _prefixIconColor,
                            ),
                            border: InputBorder.none,
                            hintText: 'Password',
                            hintStyle:
                                TextStyle(color: MyColors.textInactiveColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: FlatButton(
                        child:
                            Constants.currentFirebaseUser?.emailVerified ?? true
                                ? Text(
                                    language(
                                        en: Strings.en_forgot_password,
                                        ar: Strings.ar_forgot_password),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: MyColors.primaryColor,
                                      fontSize: 15.0,
                                    ),
                                    textAlign: TextAlign.end,
                                  )
                                : Text(
                                    "Resend verification email",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: MyColors.primaryColor,
                                      fontSize: 15.0,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                        onPressed: () async {
                          if (Constants.currentFirebaseUser?.emailVerified ??
                              true) {
                            Navigator.of(context).pushNamed('/password-reset');
                          } else {
                            AppUtil.showLoader(context);
                            await Constants.currentFirebaseUser
                                .sendEmailVerification();
                            Navigator.of(context).pop();
                            AppUtil.showToast('Verification email sent');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
                  alignment: Alignment.center,
                  child: new Row(
                    children: <Widget>[
                      new Expanded(
                        child: new FlatButton(
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(30.0),
                          ),
                          color: MyColors.primaryColor,
                          onPressed: () async {
                            AppUtil.showLoader(context);

                            await _checkFields();
                          },
                          child: new Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20.0,
                              horizontal: 20.0,
                            ),
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new Expanded(
                                  child: Text(
                                    language(en: "LOGIN", ar: 'تسجيل الدخول'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: MyColors.textLightColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
                  alignment: Alignment.center,
                  child: Row(
                    children: <Widget>[
                      new Expanded(
                        child: new Container(
                          margin: EdgeInsets.all(8.0),
                          decoration:
                              BoxDecoration(border: Border.all(width: 0.25)),
                        ),
                      ),
                      Text(
                        "OR CONNECT WITH",
                        style: TextStyle(
                          color: MyColors.textInactiveColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      new Expanded(
                        child: new Container(
                          margin: EdgeInsets.all(8.0),
                          decoration:
                              BoxDecoration(border: Border.all(width: 0.25)),
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
                  child: new Row(
                    children: <Widget>[
                      new Expanded(
                        child: new Container(
                          margin: EdgeInsets.only(right: 8.0),
                          alignment: Alignment.center,
                          child: new Row(
                            children: <Widget>[
                              new Expanded(
                                child: new FlatButton(
                                  shape: new RoundedRectangleBorder(
                                    borderRadius:
                                        new BorderRadius.circular(30.0),
                                  ),
                                  color: Color(0Xff3B5998),
                                  onPressed: () async {},
                                  child: new Container(
                                    child: new Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        new Expanded(
                                          child: new FlatButton(
                                            onPressed: () async {
                                              print('trying to login with fb');
                                              User user =
                                                  await signInWithFacebook();
                                              if (user != null) {
                                                await AppUtil
                                                    .setUserVariablesByFirebaseUser(
                                                        user);
                                                if ((await DatabaseService
                                                            .getUserWithId(
                                                                user.uid))
                                                        .id ==
                                                    null) {
                                                  String username =
                                                      await _createUsername();
                                                  await DatabaseService
                                                      .addUserToDatabase(
                                                          user.uid,
                                                          _emailController.text,
                                                          _nameController.text,
                                                          username);
                                                  //await user.sendEmailVerification();
                                                }
                                                // if (!user.isEmailVerified) {
                                                //   AppUtil.showAlertDialog(
                                                //       context: context,
                                                //       message: language(
                                                //           en: 'Please check your mail for the verification email',
                                                //           ar: 'رجاءا قم بالتفعيل عبر بريدك'),
                                                //       firstBtnText: language(en: 'OK', ar: 'تم'),
                                                //       firstFunc: () => Navigator.of(context).pop(),
                                                //       secondBtnText: language(en: 'Resend', ar: 'إعادة إرسال'),
                                                //       secondFunc: () async {
                                                //         Navigator.of(context).pop();
                                                //         await user.sendEmailVerification();
                                                //       });
                                                //   //await auth.signOut();
                                                // } else {
                                                //   saveToken(); // We don't want to saveToken for non-verified users
                                                //   //AppUtil.showToast('Logged In!');
                                                //   Navigator.of(context).pushReplacementNamed('/');
                                                //   return;
                                                // }
                                                saveToken();
                                                Navigator.of(context)
                                                    .pushReplacementNamed('/');
                                              }
                                            },
                                            padding: EdgeInsets.only(
                                              top: 10.0,
                                              bottom: 10.0,
                                            ),
                                            child: new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                Image.asset(
                                                  'assets/images/facebook.png',
                                                  height: 25,
                                                  width: 25,
                                                ),
                                                Text(
                                                  "FACEBOOK",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: MyColors
                                                          .textLightColor,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      new Expanded(
                        child: new Container(
                          margin: EdgeInsets.only(left: 8.0),
                          alignment: Alignment.center,
                          child: new Row(
                            children: <Widget>[
                              new Expanded(
                                child: new FlatButton(
                                  shape: new RoundedRectangleBorder(
                                    borderRadius:
                                        new BorderRadius.circular(30.0),
                                  ),
                                  color: Colors.blue,
                                  onPressed: () => {},
                                  child: new Container(
                                    child: new Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        new Expanded(
                                          child: new FlatButton(
                                            onPressed: () async {
                                              User user =
                                                  await signInWithGoogle();
                                              if (user != null) {
                                                await AppUtil
                                                    .setUserVariablesByFirebaseUser(
                                                        user);
                                                if ((await DatabaseService
                                                            .getUserWithId(
                                                                user.uid))
                                                        .id ==
                                                    null) {
                                                  String username =
                                                      await _createUsername();
                                                  await DatabaseService
                                                      .addUserToDatabase(
                                                          user.uid,
                                                          _emailController.text,
                                                          _nameController.text,
                                                          username);
                                                  //await user.sendEmailVerification();
                                                }
                                                // if (!user.isEmailVerified) {
                                                //   Navigator.of(context).pop();
                                                //   AppUtil.showAlertDialog(
                                                //       context: context,
                                                //       message: language(
                                                //           en: 'Please check your mail for the verification email',
                                                //           ar: 'رجاءا قم بالتفعيل عبر بريدك'),
                                                //       firstBtnText: language(en: 'OK', ar: 'تم'),
                                                //       firstFunc: () => Navigator.of(context).pop(),
                                                //       secondBtnText: language(en: 'Resend', ar: 'إعادة إرسال'),
                                                //       secondFunc: () async {
                                                //         Navigator.of(context).pop();
                                                //         await user.sendEmailVerification();
                                                //       });
                                                //   //await auth.signOut();
                                                // } else {
                                                //   saveToken(); // We don't want to saveToken for non-verified users
                                                //   //AppUtil.showToast('Logged In!');
                                                //   Navigator.of(context).pushReplacementNamed('/');
                                                //   return;
                                                // }
                                                saveToken();
                                                Navigator.of(context)
                                                    .pushReplacementNamed('/');
                                              }
                                            },
                                            padding: EdgeInsets.only(
                                              top: 10.0,
                                              bottom: 10.0,
                                            ),
                                            child: new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Image.asset(
                                                  Strings.google,
                                                  height: 25,
                                                  width: 25,
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  "GOOGLE",
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      color: MyColors
                                                          .textLightColor,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Platform.isIOS
                    ? SizedBox(
                        height: 10,
                      )
                    : Container(),
                Platform.isIOS
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: SignInWithAppleButton(
                          onPressed: () async {
                            final credential =
                                await SignInWithApple.getAppleIDCredential(
                              scopes: [
                                AppleIDAuthorizationScopes.email,
                                AppleIDAuthorizationScopes.fullName,
                              ],
                              webAuthenticationOptions:
                                  WebAuthenticationOptions(
                                // TODO: Set the `clientId` and `redirectUri` arguments to the values you entered in the Apple Developer portal during the setup
                                clientId: 'com.devyat.alhani.signin',
                                redirectUri: Uri.parse(
                                  'https://www.skippar.com',
                                ),
                              ),
                            );

                            print(credential);

                            // This is the endpoint that will convert an authorization code obtained
                            // via Sign in with Apple into a session in your system
                            final signInWithAppleEndpoint = Uri(
                              scheme: 'https',
                              host:
                                  'flutter-sign-in-with-apple-example.glitch.me',
                              path: '/sign_in_with_apple',
                              queryParameters: <String, String>{
                                'code': credential.authorizationCode,
                                'firstName': credential.givenName,
                                'lastName': credential.familyName,
                                'useBundleId':
                                    Platform.isIOS || Platform.isMacOS
                                        ? 'true'
                                        : 'false',
                                if (credential.state != null)
                                  'state': credential.state,
                              },
                            );

                            final session = await http.Client().post(
                              signInWithAppleEndpoint,
                            );

                            // If we got this far, a session based on the Apple ID credential has been created in your system,
                            // and you can now set this as the app's session
                            print(session);
                          },
                        ),
                      )
                    : Container(),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
          Positioned.fill(
              child: Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 40),
            child: Align(
              child: Builder(
                builder: (context) => InkWell(
                  onTap: () {
                    _gotoHome();
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: MyColors.primaryColor,
                    size: 30,
                  ),
                ),
              ),
              alignment: Alignment.topLeft,
            ),
          ))
        ],
      ),
    );
  }

  Widget SignupPage() {
    return new Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          colorFilter: new ColorFilter.mode(
              Colors.black.withOpacity(0.1), BlendMode.dstATop),
          image: AssetImage(Strings.splash),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: new Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      height: 220,
                      width: 220,
                      child: Center(
                          child: Image.asset(
                        Strings.app_icon,
                        scale: 1.5,
                      )),
                    ),
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 40.0, right: 40.0, top: 0.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MyColors.primaryColor,
                          width: 0.5,
                          style: BorderStyle.solid),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        child: TextField(
                          controller: _emailController,
                          obscureText: false,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: _prefixIconColor,
                            ),
                            border: InputBorder.none,
                            hintText: 'johndoe@example.com',
                            hintStyle:
                                TextStyle(color: MyColors.textInactiveColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MyColors.primaryColor,
                          width: 0.5,
                          style: BorderStyle.solid),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        child: TextField(
                          controller: _nameController,
                          obscureText: false,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: _prefixIconColor,
                            ),
                            border: InputBorder.none,
                            hintText: 'Name (ex: John Doe)',
                            hintStyle:
                                TextStyle(color: MyColors.textInactiveColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MyColors.primaryColor,
                          width: 0.5,
                          style: BorderStyle.solid),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: _prefixIconColor,
                            ),
                            border: InputBorder.none,
                            hintText: 'Password',
                            hintStyle:
                                TextStyle(color: MyColors.textInactiveColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MyColors.primaryColor,
                          width: 0.5,
                          style: BorderStyle.solid),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock,
                              color: _prefixIconColor,
                            ),
                            border: InputBorder.none,
                            hintText: 'Confirm Password',
                            hintStyle:
                                TextStyle(color: MyColors.textInactiveColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 24.0,
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: new FlatButton(
                        child: new Text(
                          language(
                              en: "Already have an account?",
                              ar: 'لديك حساب بالفعل؟'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MyColors.primaryColor,
                            fontSize: 15.0,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        onPressed: () => _gotoLogin(),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin:
                      const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
                  alignment: Alignment.center,
                  child: new Row(
                    children: <Widget>[
                      new Expanded(
                        child: new FlatButton(
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(30.0),
                          ),
                          color: MyColors.primaryColor,
                          onPressed: () async {
                            AppUtil.showLoader(context);

                            await _checkFields();
                          },
                          child: new Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20.0,
                              horizontal: 20.0,
                            ),
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new Expanded(
                                  child: Text(
                                    language(en: "SIGN UP", ar: 'تسجيل'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: MyColors.textLightColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          Positioned.fill(
              child: Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 40),
            child: Align(
              child: Builder(
                builder: (context) => InkWell(
                  onTap: () {
                    _gotoHome();
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: MyColors.primaryColor,
                    size: 30,
                  ),
                ),
              ),
              alignment: Alignment.topLeft,
            ),
          ))
        ],
      ),
    );
  }

  _gotoLogin() {
    //controller_0To1.forward(from: 0.0);
    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }

  _gotoHome() {
    _pageController.animateToPage(
      1,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }

  _gotoSignUp() {
    //controller_minus1To0.reverse(from: 0.0);
    _pageController.animateToPage(
      2,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }

  final GoogleSignIn googleSignIn = GoogleSignIn();

  PageController _pageController =
      new PageController(initialPage: 1, viewportFraction: 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
              height: MediaQuery.of(context).size.height,
              child: PageView(
                onPageChanged: (int index) {
                  _emailController.clear();
                  _nameController.clear();
                  _passwordController.clear();
                  _confirmPasswordController.clear();

                  setState(() {
                    _currentPage = index;
                  });
                },
                controller: _pageController,
                physics: new AlwaysScrollableScrollPhysics(),
                children: <Widget>[LoginPage(), HomePage(), SignupPage()],
                scrollDirection: Axis.horizontal,
              )),
        ],
      ),
    );
  }

  Future<void> _checkFields() async {
    if (_currentPage == 0) {
      if (_emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty) {
        await _login();
      } else {
        Navigator.of(context).pop();
        AppUtil.showToast(language(
            en: 'Please enter your login details', ar: 'من فضلك املأ الخانات'));
      }
    } else if (_currentPage == 2) {
      if (_emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty) {
        await _signUp();
      } else {
        Navigator.of(context).pop();
        AppUtil.showToast(language(
            en: 'Please enter your fill all fields',
            ar: 'من فضلك املأ كل الخانات'));
      }
    }
  }

  Future _signUp() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    String validEmail = AppUtil.validateEmail(_emailController.text);

    print('validEmail: $validEmail ');

    if (validEmail == null &&
        _passwordController.text == _confirmPasswordController.text) {
      // Validation Passed
      _userId = await auth.signUp(_nameController.text, _emailController.text,
          _passwordController.text);

      if (_userId == 'Email is already in use') {
        AppUtil.showToast(
            language(en: 'Email is already in use', ar: 'هذا العنوان محجوز'));
        _setFocusNode(myFocusNodeEmail);
        return;
      } else if (_userId == 'Weak Password') {
        AppUtil.showToast(
            language(en: 'Weak Password!', ar: 'كلمة مرور ضعيفة'));
        _setFocusNode(myFocusNodePassword);
        return;
      } else if (_userId == 'Invalid Email') {
        AppUtil.showToast(
            language(en: 'Invalid Email!', ar: 'البريد الإلكتروني غير صحيح'));
        _setFocusNode(myFocusNodeEmail);
        return;
      } else if (_userId == 'sign_up_error') {
        AppUtil.showToast(language(en: 'Sign up error!', ar: 'خطأ في التسجيل'));
        _setFocusNode(myFocusNodeName);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('name', _nameController.text);
      Navigator.of(context).pop();
      AppUtil.showToast(language(
          en: 'Verification Email Sent', ar: 'تم إرسال رسالة التفعيل'));
      _gotoLogin();
    } else {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppUtil.showToast(language(
            en: "Passwords don't match", ar: 'كلمتا المرور غير متطابقتان'));
        _setFocusNode(myFocusNodePassword);
        return;
      } else {
        _setFocusNode(myFocusNodeEmail);
      }
    }
  }

  Future _login() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    try {
      User user = await auth.signInWithEmailAndPassword(
          _emailController.text, _passwordController.text);
      _userId = user.uid;
      user_model.User temp = await DatabaseService.getUserWithId(_userId);

      if (user.emailVerified && temp.id == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String name = prefs.getString('name');
        String username = await _createUsername();
        await DatabaseService.addUserToDatabase(
            _userId, user.email, name, username);

        //TODO saveToken();

        Navigator.of(context).pushReplacementNamed('/');
      } else if (!user.emailVerified) {
        Navigator.of(context).pop();
        AppUtil.showAlertDialog(
            context: context,
            message: language(
                en: 'Please check your mail for the verification email',
                ar: 'رجاءا قم بالتفعيل عبر بريدك'),
            firstBtnText: language(en: 'OK', ar: 'تم'),
            firstFunc: () => Navigator.of(context).pop(),
            secondBtnText: language(en: 'Resend', ar: 'إعادة إرسال'),
            secondFunc: () async {
              Navigator.of(context).pop();
              await user.sendEmailVerification();
            });
        //await auth.signOut();
      } else {
        saveToken(); // We don't want to saveToken for non-verified users
        //AppUtil.showToast('Logged In!');
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      // Email or Password Incorrect
      //Navigator.of(context).pop();
      Navigator.of(context).pop();
      AppUtil.showToast(language(
          en: 'The email address or password is incorrect.',
          ar: 'خطأ ف البريد الإلكتروني أو كلمة المرور'));
    }
    //print('Should be true: $_loading');
  }

  Future<String> _createUsername() async {
    while (true) {
      String username = randomAlphaNumeric(6);

      QuerySnapshot snapshot =
          await usersRef.where('username', isEqualTo: username).get();
      if (snapshot.docs.length == 0) {
        return username;
      }
    }
  }

  Future<User> signInWithGoogle() async {
    final BaseAuth auth = AuthProvider.of(context).auth;
    final GoogleSignInAccount googleSignInAccount =
        await googleSignIn.signIn().catchError((onError) {
      print('google sign in error code: ${onError.code}');
      AppUtil.showToast(language(
          en: 'Unknown error, please try another sign in method!',
          ar: 'خطأ غير معروف، رجاءا استخدام طريقة أخرى'));
    });
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final User user = await auth.signInWithCredential(credential);
    setState(() {
      _nameController.text = user.displayName;
      _emailController.text = user.email;
    });
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final User currentUser = await auth.getCurrentUser();
    assert(user.uid == currentUser.uid);

    return user;
  }

  Future<User> signInWithFacebook() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    final FacebookLoginResult result = await FacebookLogin().logIn(
        permissions: [
          FacebookPermission.email,
          FacebookPermission.publicProfile
        ]);
    User user;

    switch (result.status) {
      case FacebookLoginStatus.Success:
        FacebookAccessToken facebookAccessToken = result.accessToken;
        final AuthCredential credential =
            FacebookAuthProvider.credential(facebookAccessToken.token);
        user = await auth.signInWithCredential(credential);

        print('${user.displayName} signed in');
        setState(() {
          _nameController.text = user.displayName;
          _emailController.text = user.email;
        });
        print('${user.photoURL} FACEBOOK PHOTO');
        assert(!user.isAnonymous);
        assert(await user.getIdToken() != null);

        final User currentUser = await auth.getCurrentUser();
        assert(user.uid == currentUser.uid);
        break;
      case FacebookLoginStatus.Cancel:
        print('Cancelled');
        break;
      case FacebookLoginStatus.Error:
        print('Facebook login Error');
        break;
    }
    return user;
  }

  void _setFocusNode(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
    Navigator.of(context).pop();
  }
}
