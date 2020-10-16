import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/auth.dart';
import 'package:dubsmash/services/auth_provider.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_util.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => new _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
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
          colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
          image: AssetImage('assets/images/splash.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 200.0),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 40.0,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 20.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Awesome",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "App",
                    style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 150.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: MyColors.darkPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0)),
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new OutlineButton(
                      shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                      color: MyColors.darkPrimaryColor,
                      highlightedBorderColor: Colors.white,
                      onPressed: () => _gotoSignup(),
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
                                "SIGN UP",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new FlatButton(
                      shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
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
                                "LOGIN",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: MyColors.primaryColor, fontWeight: FontWeight.bold),
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
          colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
          image: AssetImage('assets/images/splash.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(100.0),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  color: MyColors.primaryColor,
                  size: 50.0,
                ),
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MyColors.primaryColor, width: 0.5, style: BorderStyle.solid),
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
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MyColors.primaryColor, width: 0.5, style: BorderStyle.solid),
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
                        hintStyle: TextStyle(color: Colors.grey),
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
                    child: Constants.currentFirebaseUser?.isEmailVerified ?? true
                        ? Text(
                            "Forgot Password?",
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
                      if (Constants.currentFirebaseUser?.isEmailVerified ?? true) {
                        Navigator.of(context).pushNamed('/password-reset');
                      } else {
                        AppUtil.showLoader(context);
                        await Constants.currentFirebaseUser.sendEmailVerification();
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
              margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
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
                                "LOGIN",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
              alignment: Alignment.center,
              child: Row(
                children: <Widget>[
                  new Expanded(
                    child: new Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(border: Border.all(width: 0.25)),
                    ),
                  ),
                  Text(
                    "OR CONNECT WITH",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  new Expanded(
                    child: new Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(border: Border.all(width: 0.25)),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
              child: new Row(
                children: <Widget>[
                  //   new Expanded(
                  //     child: new Container(
                  //       margin: EdgeInsets.only(right: 8.0),
                  //       alignment: Alignment.center,
                  //       child: new Row(
                  //         children: <Widget>[
                  //           new Expanded(
                  //             child: new FlatButton(
                  //               shape: new RoundedRectangleBorder(
                  //                 borderRadius: new BorderRadius.circular(30.0),
                  //               ),
                  //               color: Color(0Xff3B5998),
                  //               onPressed: () => {},
                  //               child: new Container(
                  //                 child: new Row(
                  //                   mainAxisAlignment: MainAxisAlignment.center,
                  //                   children: <Widget>[
                  //                     new Expanded(
                  //                       child: new FlatButton(
                  //                         onPressed: () => {},
                  //                         padding: EdgeInsets.only(
                  //                           top: 10.0,
                  //                           bottom: 10.0,
                  //                         ),
                  //                         child: new Row(
                  //                           mainAxisAlignment:
                  //                               MainAxisAlignment.spaceEvenly,
                  //                           children: <Widget>[
                  //                             Image.asset(
                  //                               'assets/images/facebook.png',
                  //                               height: 25,
                  //                               width: 25,
                  //                             ),
                  //                             Text(
                  //                               "FACEBOOK",
                  //                               textAlign: TextAlign.center,
                  //                               style: TextStyle(
                  //                                   color: Colors.white,
                  //                                   fontWeight: FontWeight.bold),
                  //                             ),
                  //                           ],
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  new Expanded(
                    child: new Container(
                      margin: EdgeInsets.only(left: 8.0),
                      alignment: Alignment.center,
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new FlatButton(
                              shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0),
                              ),
                              color: Colors.blue,
                              onPressed: () => {},
                              child: new Container(
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Expanded(
                                      child: new FlatButton(
                                        onPressed: () async {
                                          FirebaseUser user = await signInWithGoogle();
                                          if ((await DatabaseService.getUserWithId(user.uid)).id == null) {
                                            await DatabaseService.addUserToDatabase(user.uid, user.email, null);
                                            Navigator.of(context).pushReplacementNamed('/');
                                          } else {
                                            Navigator.of(context).pushReplacementNamed('/');
                                          }
                                        },
                                        padding: EdgeInsets.only(
                                          top: 10.0,
                                          bottom: 10.0,
                                        ),
                                        child: new Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: <Widget>[
                                            Image.asset(
                                              'assets/images/google.png',
                                              height: 25,
                                              width: 25,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              "GOOGLE",
                                              textAlign: TextAlign.left,
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Widget SignupPage() {
    return new Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
          image: AssetImage(Strings.splash),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(100.0),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  color: MyColors.primaryColor,
                  size: 50.0,
                ),
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MyColors.primaryColor, width: 0.5, style: BorderStyle.solid),
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
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MyColors.primaryColor, width: 0.5, style: BorderStyle.solid),
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
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MyColors.primaryColor, width: 0.5, style: BorderStyle.solid),
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
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MyColors.primaryColor, width: 0.5, style: BorderStyle.solid),
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
                        hintStyle: TextStyle(color: Colors.grey),
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
                      "Already have an account?",
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
              margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0),
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
                                "SIGN UP",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  _gotoLogin() {
    //controller_0To1.forward(from: 0.0);
    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }

  _gotoSignup() {
    //controller_minus1To0.reverse(from: 0.0);
    _pageController.animateToPage(
      2,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  PageController _pageController = new PageController(initialPage: 1, viewportFraction: 1.0);

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
      if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        await _login();
      } else {
        Navigator.of(context).pop();
        AppUtil.showToast('Please enter your login details');
      }
    } else if (_currentPage == 2) {
      if (_emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty) {
        await _signUp();
      } else {
        Navigator.of(context).pop();
        AppUtil.showToast('Please enter your fill all fields');
      }
    }
  }

  String validateEmail(String value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      AppUtil.showToast("Email is Required");
      setState(() {
        _errorMsgEmail = "Email is Required";
      });
    } else if (!regExp.hasMatch(value)) {
      AppUtil.showToast("Invalid Email");
      setState(() {
        _errorMsgEmail = "Invalid Email";
      });
    } else {
      setState(() {
        _errorMsgEmail = null;
      });
    }
    return _errorMsgEmail;
  }

  Future _signUp() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    String validEmail = validateEmail(_emailController.text);

    print('validEmail: $validEmail ');

    if (validEmail == null && _passwordController.text == _confirmPasswordController.text) {
      // Validation Passed
      _userId = await auth.signUp(_nameController.text, _emailController.text, _passwordController.text);

      if (_userId == 'Email is already in use') {
        AppUtil.showToast('Email is already in use');
        _setFocusNode(myFocusNodeEmail);
        return;
      } else if (_userId == 'Weak Password') {
        AppUtil.showToast('Weak Password!');
        _setFocusNode(myFocusNodePassword);
        return;
      } else if (_userId == 'Invalid Email') {
        AppUtil.showToast('Invalid Email!');
        _setFocusNode(myFocusNodeEmail);
        return;
      } else if (_userId == 'sign_up_error') {
        AppUtil.showToast('Sign up error!');
        _setFocusNode(myFocusNodeName);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('name', _nameController.text);
      Navigator.of(context).pop();
      AppUtil.showToast('Verification Email Sent');
      _gotoLogin();
    } else {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppUtil.showToast("Passwords don't match");
        _setFocusNode(myFocusNodePassword);
        return;
      } else {
        if (_errorMsgEmail != null) {
          AppUtil.showToast(_errorMsgEmail);
          _setFocusNode(myFocusNodeEmail);
          return;
        } else {
          AppUtil.showToast("An Error Occurred");
          _setFocusNode(myFocusNodeEmail);
          return;
        }
      }
    }
  }

  Future _login() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    try {
      FirebaseUser user = await auth.signInWithEmailAndPassword(_emailController.text, _passwordController.text);
      _userId = user.uid;
      User temp = await DatabaseService.getUserWithId(_userId);

      if (user.isEmailVerified && temp.id == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String name = prefs.getString('name');

        await DatabaseService.addUserToDatabase(_userId, user.email, name);

        //TODO saveToken();

        Navigator.of(context).pushReplacementNamed('/');
      } else if (!user.isEmailVerified) {
        Navigator.of(context).pop();
        AppUtil.showAlertDialog(
            context: context,
            message: 'Please check your mail for the verification email',
            firstBtnText: 'OK',
            firstFunc: () => Navigator.of(context).pop(),
            secondBtnText: 'Resend',
            secondFunc: () async {
              Navigator.of(context).pop();
              await user.sendEmailVerification();
            });
        //await auth.signOut();
      } else {
        //saveToken(); // We don't want to saveToken for non-verified users
        AppUtil.showToast('Logged In!');
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      // Email or Password Incorrect
      //Navigator.of(context).pop();
      Navigator.of(context).pop();
      AppUtil.showToast('The email address or password is incorrect.');
    }
    //print('Should be true: $_loading');
  }

  Future<FirebaseUser> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn().catchError((onError) {
      print('google sign in error code: ${onError.code}');
      AppUtil.showToast('Unknown error, please try another sign in method!');
    });
    final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return user;
  }

  void _setFocusNode(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
    Navigator.of(context).pop();
  }
}
