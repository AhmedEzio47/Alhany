import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/list_items/melody_item.dart';
import 'package:dubsmash/widgets/list_items/record_item.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class MelodiesPage extends StatefulWidget {
  @override
  _MelodiesPageState createState() => _MelodiesPageState();
}

class _MelodiesPageState extends State<MelodiesPage> {
  Timestamp lastVisiblePostSnapShot;
  ScrollController _melodiesScrollController = ScrollController();
  Color _searchColor = Colors.grey.shade300;
  TextEditingController _searchController = TextEditingController();

  List<Record> _records = [];
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
      body: Container(
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
            Padding(
                padding: const EdgeInsets.only(top: 45),
                child: ListView.builder(
                    controller: _melodiesScrollController,
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {},
                        child: RecordItem(
                          record: _records[index],
                          key: ValueKey('record_item'),
                        ),
                      );
                    })),
          ],
        ),
      ),
    );
  }
}
