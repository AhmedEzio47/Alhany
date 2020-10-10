import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:dubsmash/widgets/list_items/record_item.dart';
import 'package:dubsmash/widgets/music_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class StarPage extends StatefulWidget {
  @override
  _StarPageState createState() => _StarPageState();
}

class _StarPageState extends State<StarPage> {
  List<Record> _records = [];
  getRecords() async {
    List<Record> records = await DatabaseService.getRecords();
    setState(() {
      _records = records;
    });
  }

  @override
  void initState() {
    getRecords();
    super.initState();
  }

  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          musicPlayer.stop();
          setState(() {
            _isPlaying = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: MyColors.primaryColor,
            image: DecorationImage(
              colorFilter: new ColorFilter.mode(
                  Colors.black.withOpacity(0.1), BlendMode.dstATop),
              image: AssetImage(Strings.default_bg),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  CachedImage(
                    width: MediaQuery.of(context).size.width,
                    height: 250,
                    imageShape: BoxShape.rectangle,
                    imageUrl: Constants.startUser.profileImageUrl,
                    defaultAssetImage: Strings.default_profile_image,
                  ),
                  Expanded(
                    child: ListView.builder(
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () async {
                              if (musicPlayer != null) {
                                musicPlayer.stop();
                              }
                              musicPlayer = MusicPlayer(
                                url: _records[index].audioUrl,
                                backColor: Colors.white.withOpacity(.4),
                              );
                              setState(() {
                                _isPlaying = true;
                              });
                            },
                            child: RecordItem(
                              record: _records[index],
                            ),
                          );
                        }),
                  ),
                ],
              ),
              _isPlaying
                  ? Positioned.fill(
                      child: Align(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: musicPlayer,
                      ),
                      alignment: Alignment.bottomCenter,
                    ))
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
