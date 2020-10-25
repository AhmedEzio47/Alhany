import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/auth.dart';
import 'package:dubsmash/services/auth_provider.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/custom_modal.dart';
import 'package:dubsmash/widgets/flip_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailChangePage extends StatefulWidget {
  @override
  _EmailChangePageState createState() => _EmailChangePageState();
}

class _EmailChangePageState extends State<EmailChangePage> {
  String _email = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _confirm = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        key: _scaffoldKey,
        body: Container(
          height: height,
          child: Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  image: DecorationImage(
                    colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                    image: AssetImage(Strings.splash),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 200),
                        _icon(),
                        SizedBox(height: 50),
                        _entryField('E-mail', isEmail: true),
                        SizedBox(height: 20),
                        _entryField('Confirm E-mail', isEmail: false),
                        SizedBox(height: 20),
                        _entryField('Your password', isPassword: true),
                        SizedBox(height: 20),
                        _submitButton(),
                        SizedBox(height: 100.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(top: 40, left: 0, child: _backButton())
            ],
          ),
        ));
  }

  Widget _entryField(String title, {bool isEmail = false, bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: MyColors.primaryColor, width: 0.5, style: BorderStyle.solid),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextFormField(
                onChanged: (value) {
                  isPassword ? _password = value : isEmail ? _email = value : _confirm = value;
                },
                style: TextStyle(color: Colors.black),
                obscureText: isPassword,
                decoration: InputDecoration(
                  prefixIcon: Container(
                      width: 48,
                      child: Icon(
                        isPassword ? Icons.lock_outline : isEmail ? Icons.mail_outline : Icons.email,
                        size: 30,
                        color: Colors.grey.shade400,
                      )),
                  hintText: title,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                )),
          )
        ],
      ),
    );
  }

  Widget _icon() {
    return Icon(
      Icons.music_note,
      color: MyColors.primaryColor,
      size: 50,
    );
  }

  Widget _submitButton() {
    return InkWell(
      onTap: () async {
        try {
          String validEmail = AppUtil.validateEmail(_email);
          if (validEmail != null) {
            AppUtil.showToast('Invalid email!');
            return;
          }
          if (_email != _confirm) {
            AppUtil.showToast('Two emails does not match');
            return;
          }
          AppUtil.showLoader(context);

          User user = await DatabaseService.getUserWithEmail(_email);
          if (user.id != null) {
            AppUtil.showToast('Email already in use!');
          } else {
            final BaseAuth auth = AuthProvider.of(context).auth;
            FirebaseUser firebaseUser =
                await auth.signInWithEmailAndPassword(Constants.currentFirebaseUser.email, _password);
            if (firebaseUser == null) {
              AppUtil.showToast('Wrong Password');
              return;
            }

            await firebaseUser.updateEmail(_email);
            await firebaseUser.sendEmailVerification();
            await usersRef.document(Constants.currentUserID).updateData({'email': _email});
            Constants.currentUser = await DatabaseService.getUserWithId(firebaseUser.uid);
            Constants.currentFirebaseUser = firebaseUser;
            // print('Password reset e-mail sent');
            AppUtil.showToast('Email changed, verification email sent!');
            Navigator.of(context).pop();
          }

          Navigator.of(context).pop();
        } catch (e) {
          Navigator.of(context).pop();
          AppUtil.showToast('Wrong Password');
          return;
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
                colors: [MyColors.lightPrimaryColor, MyColors.darkPrimaryColor])),
        child: Text(
          'Change Email',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

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
}