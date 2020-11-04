import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/record.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/list_items/record_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class RecordsPage extends StatefulWidget {
  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  Timestamp lastVisiblePostSnapShot;
  ScrollController _melodiesScrollController = ScrollController();
  Color _searchColor = Colors.grey.shade300;
  TextEditingController _searchController = TextEditingController();

  List<Record> _records = [];

  bool _isPlaying = false;
  getRecords() async {
    List<Record> records = await DatabaseService.getRecords();
    if (mounted) {
      setState(() {
        _records = records;
        if (_records.length > 0) this.lastVisiblePostSnapShot = records.last.timestamp;
      });
    }
  }

  nextRecords() async {
    List<Record> records = await DatabaseService.getNextRecords(lastVisiblePostSnapShot);
    if (records.length > 0) {
      setState(() {
        records.forEach((element) => _records.add(element));
        this.lastVisiblePostSnapShot = records.last.timestamp;
      });
    }
  }

  @override
  void initState() {
    getRecords();
    super.initState();

    _melodiesScrollController
      ..addListener(() {
        if (_melodiesScrollController.offset >= _melodiesScrollController.position.maxScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print('reached the bottom');
          nextRecords();
        } else if (_melodiesScrollController.offset <= _melodiesScrollController.position.minScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
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
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: MyColors.primaryColor,
            image: DecorationImage(
              colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
              image: AssetImage(Strings.default_bg),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.only(top: 45),
                    child: ListView.builder(
                        shrinkWrap: true,
                        controller: _melodiesScrollController,
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                musicPlayer = MusicPlayer(
                                  url: _records[index].audioUrl,
                                  backColor: MyColors.lightPrimaryColor.withOpacity(.8),
                                  btnSize: 35,
                                  recordBtnVisible: true,
                                  initialDuration: _records[index].duration,
                                  playBtnPosition: PlayBtnPosition.left,
                                );
                                _isPlaying = true;
                              });
                            },
                            child: RecordItem(
                              record: _records[index],
                              key: UniqueKey(),
                            ),
                          );
                        })),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Align(
                    child: Text(
                      language(en: 'Records', ar: 'التسجيلات'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    alignment: Alignment.topCenter,
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
      ),
    );
  }
}
