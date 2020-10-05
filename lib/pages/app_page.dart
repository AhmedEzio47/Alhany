import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/pages/melodies_page.dart';
import 'package:dubsmash/pages/profile_page.dart';
import 'package:dubsmash/widgets/curved_navigation_bar.dart';
import 'package:dubsmash/widgets/drawer.dart';
import 'package:flutter/material.dart';

class AppPage extends StatefulWidget {
  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  PageController _pageController;

  int _page = 1;

  @override
  void initState() {
    _pageController = PageController(initialPage: 1);
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
          items: <Widget>[
            Icon(Icons.list, size: 30),
            Icon(Icons.mic, size: 30),
            Icon(Icons.person, size: 30),
          ],
          onTap: (index) {
            navigationTapped(index);
          },
        ),
        body: PageView(
          pageSnapping: false,
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            MelodiesPage(),
            MelodiesPage(),
            ProfilePage(),
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
