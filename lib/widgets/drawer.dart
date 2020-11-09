import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/main.dart';
import 'package:Alhany/pages/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BuildDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BuildDrawerState();
}

class _BuildDrawerState extends State<BuildDrawer> {
  @override
  Widget build(BuildContext context) {
    return buildDrawer(context);
  }

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ProfilePage()));
                  },
                  child: CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage:
                        Constants.currentUser?.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                Constants.currentUser.profileImageUrl)
                            : AssetImage(Strings.default_profile_image),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        Constants.currentUser?.name ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    //Icon(Icons.arrow_drop_down)
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 0.5,
          ),
          ListTile(
            onTap: () async {
              Navigator.of(context).pushNamed('/downloads');
            },
            title: Text(
              language(en: 'Downloads', ar: 'التحميلات'),
              style: TextStyle(
                color: MyColors.primaryColor,
              ),
            ),
            leading: Icon(
              Icons.file_download,
              color: MyColors.primaryColor,
            ),
          ),
          ListTile(
            onTap: () async {
              try {
                Navigator.of(context).pushNamed('/change-email');
              } catch (e) {
                print('Sign out: $e');
              }
            },
            title: Text(
              language(en: 'Change Email', ar: 'تغيير البريد الإلكتروني'),
              style: TextStyle(
                color: MyColors.primaryColor,
              ),
            ),
            leading: Icon(
              Icons.alternate_email,
              color: MyColors.primaryColor,
            ),
          ),
          ListTile(
            onTap: () async {
              await AppUtil.switchLanguage();
              MyApp.restartApp(context);
            },
            title: Text(
              language(ar: 'تغيير اللغة', en: 'Change Language'),
              style: TextStyle(
                color: MyColors.primaryColor,
              ),
            ),
            leading: Icon(
              Icons.language,
              color: MyColors.primaryColor,
            ),
          ),
          ListTile(
            onTap: () async {
              try {
                // String token = await FirebaseMessaging().getToken();
                // usersRef
                //     .document(Constants.currentUserID)
                //     .collection('tokens')
                //     .document(token)
                //     .updateData({
                //   'modifiedAt': FieldValue.serverTimestamp(),
                //   'signed': false
                // });

                await firebaseAuth.signOut();

                setState(() {
                  Constants.currentFirebaseUser = null;
                  Constants.currentUserID = null;
                  Constants.currentUser = null;
                  authStatus = AuthStatus.NOT_LOGGED_IN;
                });
                print('Now, authStatus = $authStatus');
                Navigator.of(context).pushReplacementNamed('/');
                //moveUserTo(context: context, widget: LoginPage());
              } catch (e) {
                print('Sign out: $e');
              }
            },
            title: Text(
              language(ar: 'تسجيل الخروج', en: 'Sign Out'),
              style: TextStyle(
                color: MyColors.primaryColor,
              ),
            ),
            leading: Icon(
              Icons.power_settings_new,
              color: MyColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
