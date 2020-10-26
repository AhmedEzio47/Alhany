import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/singer_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/list_items/singer_item.dart';
import 'package:flutter/material.dart';

class SingersPage extends StatefulWidget {
  @override
  _SingersPageState createState() => _SingersPageState();
}

class _SingersPageState extends State<SingersPage> {
  List<Singer> _singers = [];

  getSingers() async {
    List<Singer> singers = await DatabaseService.getSingers();
    setState(() {
      _singers = singers;
    });
  }

  @override
  void initState() {
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
            colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
