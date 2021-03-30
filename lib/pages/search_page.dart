import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/pages/singer_page.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/list_items/singer_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Color _searchColor = Colors.white;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPlaying = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              style: TextStyle(color: _searchColor),
              controller: _searchController,
              onChanged: (text) async {
                await search(text);
              },
              decoration: InputDecoration(
                  fillColor: _searchColor,
                  focusColor: _searchColor,
                  hoverColor: _searchColor,
                  hintText: language(
                      en: 'Search melodies, songs or singers',
                      ar: 'ابحث عن ألحان، أغاني أو مطربين'),
                  disabledBorder: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                    color: _searchColor,
                  )),
                  border: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                    color: _searchColor,
                  )),
                  enabledBorder: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                    color: _searchColor,
                  )),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _searchColor,
                  ),
                  suffixIcon: InkWell(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _results = [];
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: _searchColor,
                    ),
                  ),
                  hintStyle: TextStyle(color: _searchColor)),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: MyColors.primaryColor,
                image: DecorationImage(
                  colorFilter: new ColorFilter.mode(
                      Colors.black.withOpacity(0.1), BlendMode.dstATop),
                  image: AssetImage(Strings.default_bg),
                  fit: BoxFit.cover,
                ),
              ),
              child: _results.length > 0
                  ? ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        return _results[index] is Melody
                            ? InkWell(
                                onTap: () {
                                  print('are we here?!');
                                  setState(() {
                                    musicPlayer = MusicPlayer(
                                      key: ValueKey(_results[index].id),
                                      backColor: MyColors.lightPrimaryColor
                                          .withOpacity(.8),
                                      title: _results[index].name,
                                      btnSize: 30,
                                      initialDuration: _results[index].duration,
                                      melodyList: [_results[index]],
                                    );
                                    _isPlaying = true;
                                  });
                                },
                                child: MelodyItem(
                                  melody: _results[index],
                                  isRounded: true,
                                  padding: 8,
                                ),
                              )
                            : InkWell(
                                onTap: () async {
                                  print('are we even here?!');
                                  Navigator.of(context).pushNamed('/singer-page',
                                      arguments: {'singer': _results[index], 'data_type': DataTypes.SONGS});
                                },
                                child: SingerItem(
                                  key: ValueKey('song_item'),
                                  singer: _results[index],
                                ),
                              );
                      })
                  : Center(
                      child: Text(
                        language(
                            en: 'Nothing found', ar: 'لم يتم العثور على شئ'),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
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
        ),
      ),
    );
  }

  Future search(String text) async {
    List<Melody> melodies = await searchMelodies(text.toLowerCase());
    if (melodies.length == 0) {
      List<Melody> songs = await searchSongs(text.toLowerCase());
      if (songs.length == 0) {
        print('Searching for singers');
        List<Singer> singers = await searchSingers(text.toLowerCase());
        if (singers.length == 0) {
          setState(() {
            _results = [];
          });
        } else {
          setState(() {
            _results = singers;
          });
        }
      } else {
        setState(() {
          _results = songs;
        });
      }
    } else {
      setState(() {
        _results = melodies;
      });
    }
  }

  Future<List<Melody>> searchMelodies(String text) async {
    List<Melody> melodies = await DatabaseService.searchMelodies(text);
    return melodies;
  }

  Future<List<Melody>> searchSongs(String text) async {
    List<Melody> songs = await DatabaseService.searchSongs(text);
    return songs;
  }

  Future<List<Singer>> searchSingers(String text) async {
    List<Singer> singers = await DatabaseService.searchSingers(text);
    return singers;
  }
}
