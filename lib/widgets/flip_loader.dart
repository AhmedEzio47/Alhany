import 'dart:math';

import 'package:Alhany/constants/colors.dart';
import 'package:flutter/material.dart';

class FlipLoader extends StatefulWidget {
  final Color loaderBackground;
  final Color iconColor;
  final IconData icon;
  final String animationType;
  final String shape;
  final bool rotateIcon;
  final String message;
  FlipLoader(
      {this.loaderBackground = Colors.redAccent,
        this.iconColor = Colors.white,
        this.icon = Icons.sync,
        this.animationType = "full_flip",
        this.shape = "square",
        this.rotateIcon = true,
        this.message = ''});

  @override
  _FlipLoaderState createState() => _FlipLoaderState(
      this.loaderBackground,
      this.iconColor,
      this.icon,
      this.animationType,
      this.shape,
      this.rotateIcon);
}

class _FlipLoaderState extends State<FlipLoader>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> rotationHorizontal;
  Animation<double> rotationVertical;
  Color loaderColor;
  Color iconColor;
  IconData icon;
  Widget loaderIconChild;
  String animationType;
  String shape;
  bool rotateIcon;

  _FlipLoaderState(this.loaderColor, this.iconColor, this.icon,
      this.animationType, this.shape, this.rotateIcon);

  @override
  void initState() {
    super.initState();

    controller = createAnimationController(animationType);

    controller.addStatusListener((status) {
      // Play animation backwards and forwards for full flip
      if (animationType == "half_flip") {
        if (status == AnimationStatus.completed) {
          setState(() {
            controller.repeat();
          });
        }
      }
      // play animation on repeat for half flip
      else if (animationType == "full_flip") {
        if (status == AnimationStatus.dismissed) {
          setState(() {
            controller.forward();
          });
        }
        if (status == AnimationStatus.completed) {
          setState(() {
            controller.repeat();
          });
        }
      }
      // custom animation state
      else {
        print("TODO not sure yet");
      }
    });

    controller.forward();
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  AnimationController createAnimationController([String type = 'full_flip']) {
    AnimationController animCtrl;

    switch (type) {
      case "half_flip":
        animCtrl =
            AnimationController(duration: const Duration(milliseconds: 4000));

        // Horizontal animation
        this.rotationHorizontal = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animCtrl,
                curve: Interval(0.0, 0.50, curve: Curves.linear)));

        // Vertical animation
        this.rotationVertical = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animCtrl,
                curve: Interval(0.50, 1.0, curve: Curves.linear)));
        break;
      case "full_flip":
      default:
        animCtrl = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 2000));

        this.rotationHorizontal = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animCtrl,
                curve: Interval(0.0, 0.50, curve: Curves.linear)));
        this.rotationVertical = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animCtrl,
                curve: Interval(0.50, 1.0, curve: Curves.linear)));
        break;
    }

    return animCtrl;
  }

  @override
  Widget build(BuildContext context) {
    if (animationType == "half_flip") {
      return buildHalfFlipper(context);
    } else {
      return buildFullFlipper(context);
    }
  }

  Widget buildHalfFlipper(BuildContext context) {
    return new AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: new Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.006)
                  ..rotateX(sin(2 * pi * rotationVertical.value))
                  ..rotateY(sin(2 * pi * rotationHorizontal.value)),
                alignment: Alignment.center,
                child: Container(
                    decoration: BoxDecoration(
                      shape: shape == "circle"
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: shape == "circle"
                          ? null
                          : new BorderRadius.all(const Radius.circular(8.0)),
                      color: loaderColor,
                    ),
                    width: 40.0,
                    height: 40.0,
                    child: rotateIcon == true
                        ? new RotationTransition(
                      turns: rotationHorizontal.value == 1.0
                          ? rotationVertical
                          : rotationHorizontal,
                      child: new Center(
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 20.0,
                        ),
                      ),
                    )
                        : Center(
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20.0,
                      ),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.message,
                style: TextStyle(color: MyColors.textLightColor),
              ),
            )
          ],
        );
      },
    );
  }

  Widget buildFullFlipper(BuildContext context) {
    return new AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: new Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.006)
                  ..rotateX((2 * pi * rotationVertical.value))
                  ..rotateY((2 * pi * rotationHorizontal.value)),
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    shape: shape == "circle"
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: shape == "circle"
                        ? null
                        : new BorderRadius.all(const Radius.circular(8.0)),
                    color: loaderColor,
                  ),
                  width: 40.0,
                  height: 40.0,
                  child: new Center(
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.message ?? '',
                style: TextStyle(color: MyColors.textLightColor),
              ),
            )
          ],
        );
      },
    );
  }
}
