import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:flutter/material.dart';

class RegularAppbar extends StatelessWidget {
  BuildContext context;
  Color color;
  double height;
  double margin;
  Widget leading;
  Widget trailing;
  Future<bool> Function() onBackPressed;

  RegularAppbar(BuildContext context,
      {this.color = Colors.white,
        this.height = Sizes.appbar_height,
        this.margin = 5.0,
        this.onBackPressed,
        this.leading,
        this.trailing}) {
    const double padding = 16;
    this.context = context;
    if (onBackPressed == null) {
      onBackPressed = _onBackPressed;
    }

    if (trailing == null) {
      trailing = Padding(
        padding: const EdgeInsets.only(right: padding),
        child: Container(
          height: 0,
          width: 30,
        ),
      );
    }

    if (leading == null) {
      leading = InkWell(
          onTap: onBackPressed,
          child: Padding(
            padding: const EdgeInsets.only(left: padding),
            child: Icon(
              Icons.arrow_back,
              color: color,
            ),
          ));
    }
  }
  Future<bool> _onBackPressed() {
    Constants.currentRoute = '';
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(top: margin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            Container(
              height: height,
              width: 150,
              child: Image.asset(
                Strings.app_bar,
              ),
            ),
            trailing
          ],
        ));
  }
}
