import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:flutter/material.dart';

class PasswordResetPage extends StatefulWidget {
  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  String _email = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
                    colorFilter: new ColorFilter.mode(
                        Colors.black.withOpacity(0.1), BlendMode.dstATop),
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
                        _icon(),
                        SizedBox(height: 50),
                        _entryField('E-Mail'),
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

  Widget _entryField(String title) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
              color: MyColors.primaryColor,
              width: 0.5,
              style: BorderStyle.solid),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextFormField(
                onChanged: (value) {
                  _email = value;
                },
                style: TextStyle(color: MyColors.primaryColor),
                decoration: InputDecoration(
                  prefixIcon: Container(
                      width: 48,
                      child: Icon(
                        Icons.mail_outline,
                        size: 30,
                        color: MyColors.iconInactiveColor,
                      )),
                  hintText: 'johndoe@example.com',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  border: InputBorder.none,
                )),
          )
        ],
      ),
    );
  }

  Widget _icon() {
    return Container(
      padding: EdgeInsets.only(top: 100.0),
      child: Container(
        height: 170,
        width: MediaQuery.of(context).size.width,
        child: Center(
            child: Image.asset(
          Strings.app_icon,
          scale: 1.2,
        )),
      ),
    );
  }

  Widget _submitButton() {
    return InkWell(
      onTap: () async {
        AppUtil.showLoader(context);

        User user = await DatabaseService.getUserWithEmail(_email);
        if (user.id == null) {
          print('Email is not registered!');
          AppUtil.showToast(language(
              en: 'Email is not registered!',
              ar: 'البريد الالكتروني غير مسجل'));
        } else {
          await firebaseAuth.sendPasswordResetEmail(email: _email);
          print('Password reset e-mail sent');
          AppUtil.showToast(language(
              en: 'Password reset e-mail sent',
              ar: ' تم اإرسالة رسالة إعادة تعيين كلمة المرور'));
          Navigator.of(context).pop();
        }

        Navigator.of(context).pop();
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
          language(en: 'Reset Password', ar: 'استعادة كلمة المرور'),
          style: TextStyle(fontSize: 20, color: MyColors.darkPrimaryColor),
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
              child: Icon(Icons.arrow_back, color: MyColors.iconLightColor),
            ),
          ],
        ),
      ),
    );
  }
}
