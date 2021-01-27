import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/pages/chats.dart';
import 'package:Alhany/pages/home_page.dart';
import 'package:Alhany/pages/notifications_page.dart';
import 'package:Alhany/pages/profile_page.dart';
import 'package:Alhany/pages/star_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/curved_navigation_bar.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:badges/badges.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class AppPage extends StatefulWidget {
  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> with SingleTickerProviderStateMixin {
  PageController _pageController;

  int _page = 2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User _currentUser;
  @override
  void initState() {
    initDynamicLinks();
    _currentUser = Constants.currentUser;
    NotificationHandler.receiveNotification(context, _scaffoldKey);
    userListener();
    _pageController = PageController(initialPage: 2);
    super.initState();
  }

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        if (deepLink.pathSegments[deepLink.pathSegments.length - 2] ==
            'records') {
          Record record =
              await DatabaseService.getRecordWithId(deepLink.pathSegments.last);
          Navigator.of(context).pushNamed('/record-page',
              arguments: {'record': record, 'is_video_visible': true});
        } else if (deepLink.pathSegments[deepLink.pathSegments.length - 2] ==
            'users') {
          User user =
              await DatabaseService.getUserWithId(deepLink.pathSegments.last);
          Navigator.of(context)
              .pushNamed('/profile-page', arguments: {'user_id': user.id});
        } else if (deepLink.pathSegments[deepLink.pathSegments.length - 2] ==
            'news') {
          News news =
              await DatabaseService.getNewsWithId(deepLink.pathSegments.last);
          Navigator.of(context).pushNamed('/news-page',
              arguments: {'news': news, 'is_video_visible': true});
        }
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      if (deepLink.pathSegments[deepLink.pathSegments.length - 2] ==
          'records') {
        Record record =
            await DatabaseService.getRecordWithId(deepLink.pathSegments.last);
        Navigator.of(context).pushNamed('/record-page',
            arguments: {'record': record, 'is_video_visible': true});
      } else if (deepLink.pathSegments[deepLink.pathSegments.length - 2] ==
          'users') {
        User user =
            await DatabaseService.getUserWithId(deepLink.pathSegments.last);
        Navigator.of(context)
            .pushNamed('/profile-page', arguments: {'user_id': user.id});
      } else if (deepLink.pathSegments[deepLink.pathSegments.length - 2] ==
          'news') {
        News news =
            await DatabaseService.getNewsWithId(deepLink.pathSegments.last);
        Navigator.of(context).pushNamed('/news-page',
            arguments: {'news': news, 'is_video_visible': true});
      }
    }
  }

  userListener() {
    usersRef.snapshots().listen((querySnapshot) {
      querySnapshot.docChanges.forEach((change) {
        if (mounted) {
          setState(() {
            if (change.doc.id == Constants.currentUserID) {
              Constants.currentUser = User.fromDoc(change.doc);
              setState(() {
                _currentUser = Constants.currentUser;
              });
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: BuildDrawer(),
        bottomNavigationBar: CurvedNavigationBar(
          index: _page,
          height: 55,
          backgroundColor: MyColors.primaryColor,
          color: MyColors.accentColor,
          items: <Widget>[
            Icon(Icons.star, size: 30),
            (_currentUser?.notificationsNumber ?? 0) > 0
                ? Badge(
                    badgeColor: MyColors.accentColor,
                    badgeContent: Text(_currentUser.notificationsNumber < 9
                        ? _currentUser?.notificationsNumber.toString()
                        : '+9'),
                    child: Icon(
                      Icons.notifications,
                      size: 30,
                    ),
                    toAnimate: true,
                    animationType: BadgeAnimationType.scale,
                  )
                : Icon(
                    Icons.notifications,
                    size: 30,
                  ),
            Icon(Icons.home, size: 30),
            Icon(Icons.chat, size: 30),
            Icon(Icons.person, size: 30),
          ],
          onTap: (index) {
            navigationTapped(index);
          },
        ),
        body: Stack(
          children: [
            PageView(
              physics: NeverScrollableScrollPhysics(),
              pageSnapping: false,
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                StarPage(),
                NotificationsPage(),
                HomePage(),
                Chats(),
                ProfilePage(
                  userId: Constants.currentUserID,
                ),
              ],
            ),
          ],
        ));
  }

  void navigationTapped(int page) {
//    _pageController.animateToPage(page,
//        duration: Duration(milliseconds: 400), curve: Curves.easeOut);
    _pageController.jumpToPage(page);
  }

  void _onPageChanged(int page) {
    print('index: $page');
    if (mounted) {
      setState(() {
        this._page = page;
      });
      if (page == 1) {
        NotificationHandler().clearNotificationsNumber();
      }
    }
  }
}
