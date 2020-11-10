import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/pages/chats.dart';
import 'package:Alhany/pages/home_page.dart';
import 'package:Alhany/pages/melodies_page.dart';
import 'package:Alhany/pages/notifications_page.dart';
import 'package:Alhany/pages/profile_page.dart';
import 'package:Alhany/pages/records_page.dart';
import 'package:Alhany/pages/singers_page.dart';
import 'package:Alhany/pages/star_page.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/curved_navigation_bar.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';

class AppPage extends StatefulWidget {
  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  PageController _pageController;

  int _page = 2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    NotificationHandler.receiveNotification(context, _scaffoldKey);
    _pageController = PageController(initialPage: 2);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: BuildDrawer(),
        bottomNavigationBar: CurvedNavigationBar(
          index: _page,
          height: 55,
          backgroundColor: MyColors.primaryColor,
          color: Colors.white,
          items: <Widget>[
            Icon(Icons.star, size: 30),
            (Constants.currentUser?.notificationsNumber ?? 0) > 0
                ? Badge(
                    badgeColor: MyColors.accentColor,
                    badgeContent: Text(Constants.currentUser.notificationsNumber < 9
                        ? Constants.currentUser?.notificationsNumber.toString()
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
            Positioned.fill(
                child: Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 40),
              child: Align(
                child: Builder(
                  builder: (context) => InkWell(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Icon(
                      Icons.menu,
                      color: Colors.white,
                    ),
                  ),
                ),
                alignment: Alignment.topLeft,
              ),
            ))
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
