import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class MelodiesPage extends StatefulWidget {
  @override
  _MelodiesPageState createState() => _MelodiesPageState();
}

class _MelodiesPageState extends State<MelodiesPage> {
  Timestamp lastVisiblePostSnapShot;
  ScrollController _melodiesScrollController = ScrollController();
  bool _isSearching = false;
  Color _searchColor = Colors.grey.shade300;
  TextEditingController _searchController = TextEditingController();

  List<Melody> _melodies = [];
  List<Melody> _filteredMelodies = [];

  getMelodies() async {
    List<Melody> melodies = await DatabaseService.getMelodies();
    setState(() {
      _melodies = melodies;
      if (_melodies.length > 0) this.lastVisiblePostSnapShot = melodies.last.timestamp;
    });
  }

  nextMelodies() async {
    List<Melody> melodies = await DatabaseService.getNextMelodies(lastVisiblePostSnapShot);
    if (melodies.length > 0) {
      setState(() {
        melodies.forEach((element) => _melodies.add(element));
        this.lastVisiblePostSnapShot = melodies.last.timestamp;
      });
    }
  }

  searchMelodies(String text) async {
    List<Melody> filteredMelodies = await DatabaseService.searchMelodies(text);
    if (mounted) {
      setState(() {
        _filteredMelodies = filteredMelodies;
      });
    }
  }

  @override
  void initState() {
    getMelodies();
    super.initState();

    _melodiesScrollController
      ..addListener(() {
        if (_melodiesScrollController.offset >= _melodiesScrollController.position.maxScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print('reached the bottom');
          if (!_isSearching) nextMelodies();
        } else if (_melodiesScrollController.offset <= _melodiesScrollController.position.minScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        onTap: () {
          setState(() {
            _isSearching = false;
          });
        },
        child: Container(
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
                child: !_isSearching
                    ? ListView.builder(
                        controller: _melodiesScrollController,
                        itemCount: _melodies.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pushNamed('/melody-page', arguments: {'melody': _melodies[index]});
                            },
                            child: MelodyItem(
                              melody: _melodies[index],
                              key: ValueKey('melody_item'),
                            ),
                          );
                        })
                    : ListView.builder(
                        controller: _melodiesScrollController,
                        itemCount: _filteredMelodies.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed('/melody-page', arguments: {'melody': _filteredMelodies[index]});
                            },
                            child: MelodyItem(
                              melody: _filteredMelodies[index],
                            ),
                          );
                        }),
              ),
              _searchBar(),
              _isSearching
                  ? Container()
                  : Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Align(
                          child: Text(
                            language(en: 'Melodies', ar: 'الألحان'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: InkWell(
            onTap: () {
              setState(() {
                _isSearching = true;
              });
            },
            child: _isSearching
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      style: TextStyle(color: _searchColor),
                      controller: _searchController,
                      onChanged: (text) async {
                        await searchMelodies(text.toLowerCase());
                      },
                      decoration: InputDecoration(
                          fillColor: _searchColor,
                          focusColor: _searchColor,
                          hoverColor: _searchColor,
                          hintText: 'Search melodies...',
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
                              _filteredMelodies = [];
                            },
                            child: Icon(
                              Icons.close,
                              color: _searchColor,
                            ),
                          ),
                          hintStyle: TextStyle(color: _searchColor)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 20.0, top: 20),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
