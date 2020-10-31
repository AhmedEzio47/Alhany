import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: MyColors.primaryColor,
          image: DecorationImage(
            colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
            image: AssetImage(Strings.default_bg),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _singerNames.length,
            itemBuilder: (context, index) {
              return _songs[_singerNames[index]]?.length > 0
                  ? Container(
                      margin: EdgeInsets.all(8),
                      height: 200,
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _singerNames[index],
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: ListView.builder(
                                itemCount: _songs[_singerNames[index]].length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index2) {
                                  return Container(
                                    height: 150,
                                    width: 150,
                                    child: Column(
                                      children: [
                                        CachedImage(
                                          width: 120,
                                          height: 120,
                                          imageShape: BoxShape.rectangle,
                                          imageUrl: _songs[_singerNames[index]][index2].imageUrl,
                                          defaultAssetImage: Strings.default_melody_image,
                                        ),
                                        Text(
                                          _songs[_singerNames[index]][index2].name,
                                          style: TextStyle(color: Colors.white),
                                        )
                                      ],
                                    ),
                                  );
                                }),
                          )
                        ],
                      ),
                    )
                  : Container();
            }),
      ),
    );
  }

  List<Singer> _singers = [];
  List<String> _singerNames = [];
  Map<String, List<Melody>> _songs = {};

  getSingers() async {
    List<Singer> singers = await DatabaseService.getSingers();
    setState(() {
      _singers = singers;
    });

    for (Singer singer in singers) {
      setState(() {
        _singerNames.add(singer.name);
      });

      print(singer.name);

      List<Melody> songs = await DatabaseService.getSongsBySingerName(singer.name);
      setState(() {
        _songs.putIfAbsent(singer.name, () => songs);
      });
    }
  }

  @override
  void initState() {
    getSingers();
    super.initState();
  }
}
