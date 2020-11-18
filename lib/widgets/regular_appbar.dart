import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:flutter/material.dart';

class RegularAppbar extends StatelessWidget {
  BuildContext context;
  Color color;
  double margin;
  Future<bool> Function() onBackPressed;

  RegularAppbar(BuildContext context, {this.color = Colors.white, this.margin = 40, this.onBackPressed}) {
    this.context = context;
    if (onBackPressed == null) {
      onBackPressed = _onBackPressed;
    }
  }
  Future<bool> _onBackPressed() {
    Constants.currentRoute = '';
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 16;
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(top: margin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
                onTap: onBackPressed,
                child: Padding(
                  padding: const EdgeInsets.only(left: padding),
                  child: Icon(
                    Icons.arrow_back,
                    color: color,
                  ),
                )),
            Container(
              height: 40,
              width: 150,
              child: Image.asset(
                Strings.app_bar,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: padding),
              child: Container(
                height: 0,
                width: 30,
              ),
            )
          ],
        ));
  }
}
