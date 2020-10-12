import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/pages/profile_page.dart';
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                  },
                  child: CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: Constants.currentUser?.profileImageUrl != null
                        ? CachedNetworkImageProvider(Constants.currentUser.profileImageUrl)
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
              Navigator.of(context).pushNamed('/favourites');
            },
            title: Text(
              'Favourites',
            ),
            leading: Icon(
              Icons.favorite,
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
              'Sign Out',
            ),
            leading: Icon(
              Icons.power_settings_new,
            ),
          ),
        ],
      ),
    );
  }
}
