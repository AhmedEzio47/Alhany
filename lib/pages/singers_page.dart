import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/list_items/singer_item.dart';
import 'package:flutter/material.dart';

class SingersPage extends StatefulWidget {
  @override
  _SingersPageState createState() => _SingersPageState();
}

class _SingersPageState extends State<SingersPage> {
  List<Singer> _singers = [];

  String? lastVisiblePostSnapShot;

  ScrollController? _singersScrollController;

  getSingers() async {
    List<Singer> singers = await DatabaseService.getSingers();
    setState(() {
      _singers = singers;
      lastVisiblePostSnapShot = singers.last.name;
    });
  }

  nextSingers() async {
    if (lastVisiblePostSnapShot != null) {
      List<Singer> singers =
          await DatabaseService.getNextSingers(lastVisiblePostSnapShot!);
      if (singers.length > 0) {
        setState(() {
          singers.forEach((element) => _singers.add(element));
          this.lastVisiblePostSnapShot = singers.last.name;
        });
      }
    }
  }

  @override
  void initState() {
    if (_singersScrollController != null) {
      _singersScrollController
        ?..addListener(() {
          if (_singersScrollController!.offset >=
                  _singersScrollController!.position.maxScrollExtent &&
              !_singersScrollController!.position.outOfRange) {
            print('reached the bottom');
            nextSingers();
          } else if (_singersScrollController!.offset <=
                  _singersScrollController!.position.minScrollExtent &&
              !_singersScrollController!.position.outOfRange) {
            print("reached the top");
          } else {}
        });
    }
    getSingers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                  ),
                  ListView.builder(
                      controller: _singersScrollController,
                      shrinkWrap: true,
                      itemCount: _singers.length,
                      itemBuilder: (context, index) {
                        return SingerItem(
                          singer: _singers[index],
                        );
                      }),
                ],
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Align(
                  child: Text(
                    language(en: 'Singers', ar: 'المطربون'),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MyColors.textLightColor),
                  ),
                  alignment: Alignment.topCenter,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
