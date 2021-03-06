import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/services/auth.dart';
import 'package:Alhany/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordChangePage extends StatefulWidget {
  PasswordChangePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _PasswordChangePageState createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  bool _isObscure = true;

  String _newPassword = '';

  String _confirmPassword = '';

  String _currentPassword = '';

  String userId = "";

  final FocusNode myFocusNodeCurrentPassword = FocusNode();
  final FocusNode myFocusNodeNewPassword = FocusNode();
  final FocusNode myFocusNodeConfirmPassword = FocusNode();

  Widget _backButton() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 0, top: 10, bottom: 10),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryField(String title,
      {FocusNode focusNode,
      bool isCurrentPassword = false,
      bool isNewPassword = false,
      bool isConfirmPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextFormField(
                focusNode: focusNode,
                onChanged: (value) {
                  if (isCurrentPassword) {
                    setState(() {
                      _currentPassword = value;
                    });
                  } else if (isNewPassword) {
                    setState(() {
                      _newPassword = value;
                    });
                  } else if (isConfirmPassword) {
                    _confirmPassword = value;
                  }
                },
                onFieldSubmitted: (v) {
                  if (isCurrentPassword) {
                    FocusScope.of(context).requestFocus(myFocusNodeNewPassword);
                  } else if (isNewPassword) {
                    FocusScope.of(context)
                        .requestFocus(myFocusNodeConfirmPassword);
                  } else if (isConfirmPassword) {
                    _changePassword();
                  }
                },
                textInputAction: isConfirmPassword
                    ? TextInputAction.done
                    : TextInputAction.next,
                style: TextStyle(color: MyColors.primaryColor),
                obscureText: _isObscure,
                decoration: InputDecoration(
                    hintText: title,
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Container(
                        width: 48,
                        child: Icon(
                          Icons.lock,
                          size: 18,
                          color: Colors.grey.shade400,
                        )),
                    suffixIcon: Container(
                      width: 48,
                      child: _isObscure
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                              icon: Icon(
                                Icons.remove_red_eye,
                                size: 18,
                              ),
                              color: Colors.grey.shade400,
                            )
                          : isCurrentPassword ||
                                  isNewPassword ||
                                  isConfirmPassword
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.visibility_off,
                                    size: 18,
                                  ),
                                  color: Colors.grey.shade400,
                                )
                              : Container(),
                    ),
                    border: InputBorder.none,
                    fillColor: Color(0xfff3f3f4),
                    filled: true)),
          )
        ],
      ),
    );
  }

  Widget _submitButton() {
    return InkWell(
      onTap: () async {
        if (_newPassword.isNotEmpty && _confirmPassword.isNotEmpty) {
          await _changePassword();
        } else {
          AppUtil.showToast(language(
              en: 'Please fill fields above!', ar: 'من فضلك املأ كل الخانات'));
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerRight,
                colors: [MyColors.primaryColor, MyColors.primaryColor])),
        child: Text(
          language(en: 'Change Password', ar: 'تغيير كلمة المرور'),
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _icon() {
    return Image.asset(
      'assets/images/icon-480.png',
      height: 200.0,
    );
  }

  Widget _textFieldWidgets() {
    return Column(
      children: <Widget>[
        _entryField("Current Password",
            focusNode: myFocusNodeCurrentPassword, isCurrentPassword: true),
        _entryField("Password",
            focusNode: myFocusNodeNewPassword, isNewPassword: true),
        _entryField("Confirm Password",
            focusNode: myFocusNodeConfirmPassword, isConfirmPassword: true)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      key: _scaffoldKey,
      body: Container(
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -MediaQuery.of(context).size.height * .15,
              right: -MediaQuery.of(context).size.width * .4,
              child: Icon(Icons.music_note),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 150),
                    //_icon(),
                    SizedBox(
                      height: 50,
                    ),
                    _textFieldWidgets(),
                    SizedBox(
                      height: 20,
                    ),
                    _submitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _loading = false;

  @override
  void dispose() {
    super.dispose();
    myFocusNodeCurrentPassword.dispose();
    myFocusNodeConfirmPassword.dispose();
    myFocusNodeNewPassword.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  searchList(String text) {
    List<String> list = [];
    for (int i = 1; i <= text.length; i++) {
      list.add(text.substring(0, i).toLowerCase());
    }
    return list;
  }

  Future _changePassword() async {
    final BaseAuth baseAuth = AuthProvider.of(context).auth;

    AppUtil.showLoader(context);

    try {
      String email = (await firebaseAuth.currentUser.email);
      await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: _currentPassword);
    } catch (ex) {
      print('authResult: ${ex.toString()}');

      if (ex.code == 'ERROR_WRONG_PASSWORD') {
        AppUtil.showToast(language(
            en: 'Current Password is not correct!',
            ar: 'كلمة المرور الحالية غير صحيحة'));
        Navigator.of(context).pop();
        return;
      }
    }

    if (_newPassword == _confirmPassword) {
      // Validation Passed

      String errorCode = await baseAuth.changePassword(_newPassword);
      print('change pass error: $errorCode');
      if (errorCode == null) {
        AppUtil.showToast(language(
            en: 'Password changed successfully',
            ar: 'تم تغيير كلمة المرور بنجاح'));
        firebaseAuth.signOut();
        Navigator.of(context).pushReplacementNamed('/login',
            arguments: {'on_sign_up_callback': false});
      } else {
        if (errorCode == 'ERROR_WEAK_PASSWORD') {
          AppUtil.showToast(
              language(en: 'Weak password!', ar: 'كلمة مرور ضعيفة'));
        }
      }
    } else {
      if (_newPassword != _confirmPassword) {
        AppUtil.showToast(language(
            en: "Passwords don't match", ar: 'كلمتا المرور غير متطابقتان'));
        myFocusNodeNewPassword.requestFocus();
      } else {}
    }

    Navigator.of(context).pop();

    print('Should be false: $_loading');
  }
}
