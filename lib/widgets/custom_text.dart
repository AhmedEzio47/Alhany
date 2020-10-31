import 'package:Alhany/constants/sizes.dart';
import 'package:flutter/material.dart';

Widget customText(String msg,
    {Key key,
    TextStyle style,
    TextAlign textAlign = TextAlign.justify,
    TextOverflow overflow = TextOverflow.visible,
    BuildContext context,
    bool softwrap = true}) {
  if (msg == null) {
    return SizedBox(
      height: 0,
      width: 0,
    );
  } else {
    if (context != null && style != null) {
      var fontSize = style.fontSize ?? Theme.of(context).textTheme.bodyText2.fontSize;
      style = style.copyWith(
        fontSize: fontSize - (Sizes.fullWidth(context) <= 375 ? 2 : 0),
      );
    }
    return Text(
      msg,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      softWrap: softwrap,
      key: key,
    );
  }
}
