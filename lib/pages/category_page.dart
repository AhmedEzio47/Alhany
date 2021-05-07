import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/pages/singer_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/list_items/singer_item.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  final String category;

  const CategoryPage({Key? key, required this.category}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Singer> _singers = [];
  ScrollController _songsScrollController = ScrollController();
  String? lastVisiblePostSnapShot;

  bool _isPlaying = false;

  getSingers() async {
    List<Singer> songs =
        await DatabaseService.getSingersByCategory(widget.category);
    if (mounted) {
      setState(() {
        _singers = songs;
        if (_singers.length > 0)
          this.lastVisiblePostSnapShot = _singers.last.name;
      });
    }
  }

  nextSingers() async {
    if (lastVisiblePostSnapShot != null) {
      List<Singer> singers = await DatabaseService.getNextSingersByCategory(
          widget.category, lastVisiblePostSnapShot!);
      if (singers.length > 0) {
        setState(() {
          singers.forEach((element) => _singers.add(element));
          this.lastVisiblePostSnapShot = singers.last.name;
        });
      }
    }
  }

  _songsPage() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: ListView.builder(
              shrinkWrap: true,
              controller: _songsScrollController,
              itemCount: _singers.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    Navigator.of(context).pushNamed('/singer-page', arguments: {
                      'singer': _singers[index],
                      'data_type': DataTypes.SONGS
                    });
                  },
                  child: SingerItem(
                    key: ValueKey('song_item'),
                    singer: _singers[index],
                  ),
                );
              }),
        ),
        _isPlaying
            ? Positioned.fill(
                child: Align(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: musicPlayer,
                ),
                alignment: Alignment.bottomCenter,
              ))
            : Container(),
      ],
    );
  }

  @override
  void initState() {
    getSingers();
    _songsScrollController
      ..addListener(() {
        if (_songsScrollController.offset >=
                _songsScrollController.position.maxScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print('reached the bottom');
          nextSingers();
        } else if (_songsScrollController.offset <=
                _songsScrollController.position.minScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isPlaying = false;
          });
        },
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: MyColors.primaryColor,
                image: DecorationImage(
                  colorFilter: new ColorFilter.mode(
                      Colors.black.withOpacity(0.1), BlendMode.dstATop),
                  image: AssetImage(Strings.default_bg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Text(
                      widget.category,
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    Expanded(
                      child: _songsPage(),
                    )
                  ],
                ),
              ),
            ),
            RegularAppbar(context)
          ],
        ),
      ),
    );
  }
}
