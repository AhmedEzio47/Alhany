import 'package:flutter/material.dart';

class CustomOverlay extends StatelessWidget {
  final Widget child;
  final Icon icon;
  final BoxShape shape;
  final double size;

  const CustomOverlay({Key key, this.icon, this.shape, this.size, this.child})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Container(
          child: icon,
          decoration: BoxDecoration(
            shape: shape,
            color: Colors.black38.withOpacity(.6),
          ),
          height: size,
          width: size,
        ),
      ],
    );
  }
}
