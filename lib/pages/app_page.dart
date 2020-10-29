import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/pages/home_page.dart';
import 'package:dubsmash/pages/melodies_page.dart';
import 'package:dubsmash/pages/profile_page.dart';
import 'package:dubsmash/pages/records_page.dart';
import 'package:dubsmash/pages/singers_page.dart';
import 'package:dubsmash/pages/star_page.dart';
import 'package:dubsmash/widgets/curved_navigation_bar.dart';
import 'package:dubsmash/widgets/drawer.dart';
import 'package:flutter/material.dart';

class AppPage extends StatefulWidget {
  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  PageController _pageController;

  int _page = 2;

  @override
  void initState() {
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
            Icon(Icons.home, size: 30),
            Icon(Icons.group, size: 30),
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
                RecordsPage(),
                SingersPage(),
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
    }
  }
}
