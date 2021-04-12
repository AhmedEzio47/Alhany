import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:Alhany/widgets/list_items/melody_item.dart';
import 'package:Alhany/widgets/music_player.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

enum DataTypes { SONGS, MELODIES }

class SingerPage extends StatefulWidget {
  final Singer? singer;
  final DataTypes? dataType;

  const SingerPage({Key? key, this.singer, this.dataType}) : super(key: key);

  @override
  _SingerPageState createState() => _SingerPageState();
}

class _SingerPageState extends State<SingerPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int? _page;
  ScrollController _songsScrollController = ScrollController();
  ScrollController _melodiesScrollController = ScrollController();
  List<Melody> _songs = [];
  List<Melody> _melodies = [];

  bool _isPlaying = false;

  Timestamp? lastVisiblePostSnapShot;

  getSongs() async {
    List<Melody> songs =
        await DatabaseService.getSongsBySingerName(widget.singer!.name!);
    if (mounted) {
      setState(() {
        _songs = songs;
        lastVisiblePostSnapShot = songs.last.timestamp;
      });
    }
  }

  nextSongs() async {
    List<Melody> songs = await DatabaseService.getNextSongsBySingerName(
        widget.singer!.name!, lastVisiblePostSnapShot!);
    if (songs.length > 0) {
      setState(() {
        songs.forEach((element) => _songs.add(element));
        this.lastVisiblePostSnapShot = songs.last.timestamp;
      });
    }
  }

  getMelodies() async {
    List<Melody> melodies =
        await DatabaseService.getMelodiesBySingerName(widget.singer!.name!);
    if (mounted) {
      setState(() {
        _melodies = melodies;
      });
    }
  }

  nextMelodies() async {
    List<Melody> melodies = await DatabaseService.getNextMelodiesBySingerName(
        widget.singer!.name!, lastVisiblePostSnapShot!);
    if (melodies.length > 0) {
      setState(() {
        melodies.forEach((element) => _melodies.add(element));
        this.lastVisiblePostSnapShot = melodies.last.timestamp;
      });
    }
  }

  @override
  void initState() {
    widget.dataType == DataTypes.SONGS ? _page = 1 : _page = 0;
    _songsScrollController
      ..addListener(() {
        if (_songsScrollController.offset >=
                _songsScrollController.position.maxScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print('reached the bottom');
          nextSongs();
        } else if (_songsScrollController.offset <=
                _songsScrollController.position.minScrollExtent &&
            !_songsScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });

    _melodiesScrollController
      ..addListener(() {
        if (_melodiesScrollController.offset >=
                _melodiesScrollController.position.maxScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print('reached the bottom');
          nextMelodies();
        } else if (_melodiesScrollController.offset <=
                _melodiesScrollController.position.minScrollExtent &&
            !_melodiesScrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    _tabController = TabController(vsync: this, length: 2, initialIndex: 1);
    super.initState();
  }

  _currentPage() {
    switch (_page) {
      case 0:
        getMelodies();
        return _melodiesPage();
      case 1:
        getSongs();
        return _songsPage();
    }
  }

  _songsPage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListView.builder(
          primary: false,
          shrinkWrap: true,
          controller: _songsScrollController,
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () async {
                setState(() {
                  musicPlayer = MusicPlayer(
                    key: ValueKey(_songs[index].id),
                    melodyList: [_songs[index]],
                    backColor: MyColors.lightPrimaryColor,
                    title: _songs[index].name,
                    initialDuration: _songs[index].duration,
                  );
                  _isPlaying = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
                child: MelodyItem(
                  padding: 0,
                  imageSize: 40,
                  isRounded: false,
                  key: ValueKey('song_item'),
                  melody: _songs[index],
                ),
              ),
            );
          }),
    );
  }

  _melodiesPage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListView.builder(
          primary: false,
          shrinkWrap: true,
          controller: _melodiesScrollController,
          itemCount: _melodies.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () async {
                setState(() {
                  musicPlayer = MusicPlayer(
                    key: ValueKey(_melodies[index].id),
                    melodyList: [_melodies[index]],
                    backColor: MyColors.lightPrimaryColor,
                    title: _melodies[index].name,
                    initialDuration: _melodies[index].duration,
                    isRecordBtnVisible: true,
                  );
                  _isPlaying = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
                child: MelodyItem(
                  padding: 0,
                  imageSize: 40,
                  isRounded: false,
                  key: ValueKey('melody_item'),
                  melody: _melodies[index],
                ),
              ),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlaying = false;
                  });
                },
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: new LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        MyColors.primaryColor,
                      ],
                    ),
                    color: MyColors.primaryColor,
                    image: DecorationImage(
                      colorFilter: new ColorFilter.mode(
                          Colors.black.withOpacity(0.1), BlendMode.dstATop),
                      image: AssetImage(Strings.default_bg),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Container(
                            height: 200,
                            child: Stack(
                              children: [
                                CachedImage(
                                  height: 200,
                                  width: MediaQuery.of(context).size.width,
                                  defaultAssetImage:
                                      Strings.default_cover_image,
                                  imageUrl: widget.singer!.coverUrl!,
                                  imageShape: BoxShape.rectangle,
                                ),
                                Positioned.fill(
                                    child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, bottom: 16),
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: CachedImage(
                                      height: 100,
                                      width: 100,
                                      defaultAssetImage:
                                          Strings.default_profile_image,
                                      imageUrl: widget.singer!.imageUrl!,
                                      imageShape: BoxShape.circle,
                                    ),
                                  ),
                                )),
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 16),
                                        color: Colors.black.withOpacity(.6),
                                        child: Text(
                                          widget.singer!.name!,
                                          style: TextStyle(
                                              fontSize: 22,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          widget.dataType == null
                              ? TabBar(
                                  onTap: (index) {
                                    setState(() {
                                      //_isPlaying = false;
                                      _page = index;
                                    });
                                  },
                                  labelColor: MyColors.accentColor,
                                  unselectedLabelColor: Colors.grey,
                                  controller: _tabController,
                                  tabs: [
                                      Tab(
                                        text: language(
                                            en: 'Melodies', ar: 'الألحان'),
                                      ),
                                      Tab(
                                        text: language(
                                            en: 'Songs', ar: 'الأغاني'),
                                      ),
                                    ])
                              : Container(),
                          _currentPage()
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: RegularAppbar(
                    context,
                    color: Colors.black,
                    margin: 10,
                  ),
                ),
              ),
              Constants.isAdmin
                  ? Positioned.fill(
                      child: Align(
                      alignment: Alignment.topRight,
                      child: PopupMenuButton<String>(
                        color: MyColors.accentColor,
                        elevation: 0,
                        onCanceled: () {
                          print('You have not chosen anything');
                        },
                        tooltip: 'This is tooltip',
                        onSelected: _select,
                        itemBuilder: (BuildContext context) {
                          return choices.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(
                                choice,
                                style: TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ))
                  : Container(),
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

  Future<bool> _onBackPressed() async{
    Constants.currentRoute = '';
    Navigator.of(context).pop();
    return true;
  }

  var choices = ['Edit Image', 'Edit Name', 'Delete'];

  TextEditingController _nameController = TextEditingController();
  void _select(String value) async {
    switch (value) {
      case 'Edit Image':
        await editImage();
        break;

      case 'Edit Name':
        await editName();
        break;

      case 'Delete':
        await deleteSinger();
        break;
    }
  }

  editImage() async {
    File image = await AppUtil.pickImageFromGallery();
    String ext = path.extension(image.path);

    if (widget.singer!.imageUrl != null) {
      String fileName =
          await AppUtil.getStorageFileNameFromUrl(widget.singer!.imageUrl!);
      await storageRef.child('/singers_images/$fileName').delete();
    }

    String url = await AppUtil()
        .uploadFile(image, context, '/singers_images/${widget.singer!.id}$ext');
    await singersRef.doc(widget.singer!.id).update({'image_url': url});
    AppUtil.showToast(language(en: 'Image updated!', ar: 'تم تغيير الصورة'));
  }

  editName() async {
    setState(() {
      _nameController.text = widget.singer!.name!;
    });
    Navigator.of(context).push(CustomModal(
        child: Container(
      height: 200,
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(hintText: 'New name'),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) {
                AppUtil.showToast(
                    language(en: 'Please enter a name', ar: 'قم بإدخال اسم'));
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              await singersRef.doc(widget.singer!.id).update({
                'name': _nameController.text,
                'search': searchList(_nameController.text),
              });
              AppUtil.showToast(
                  language(en: 'Name Updated', ar: 'تم تغيير الاسم'));
              Navigator.of(context).pop();
            },
            color: MyColors.primaryColor,
            child: Text(
              'Update',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    )));
  }

  deleteSinger() async {
    AppUtil.showAlertDialog(
        context: context,
        message: 'Are you sure you want to delete this singer?',
        firstBtnText: 'Yes',
        firstFunc: () async {
          Navigator.of(context).pop();
          AppUtil.showLoader(context);
          if (widget.singer!.imageUrl != null) {
            String fileName =
                await AppUtil.getStorageFileNameFromUrl(widget.singer!.imageUrl!);
            await storageRef.child('/singers_images/$fileName').delete();
          }
          if (widget.singer!.coverUrl != null) {
            String fileName =
                await AppUtil.getStorageFileNameFromUrl(widget.singer!.coverUrl!);
            await storageRef.child('/singers_covers/$fileName').delete();
          }
          List<Melody> songs =
              await DatabaseService.getSongsBySingerName(widget.singer!.name!);
          if (songs != null) {
            for (Melody song in songs) {
              await DatabaseService.deleteMelody(song);
            }
          }

          List<Melody> melodies =
              await DatabaseService.getMelodiesBySingerName(widget.singer!.name!);
          if (melodies != null) {
            for (Melody melody in melodies) {
              await DatabaseService.deleteMelody(melody);
            }
          }

          await singersRef.doc(widget.singer!.id).delete();
          AppUtil.showToast('Deleted!');
          Navigator.of(context).pop();
        },
        secondBtnText: 'No',
        secondFunc: () {
          Navigator.of(context).pop();
        });
  }
}
