import 'dart:async';
import 'dart:io';

import 'package:dubsmash/constants/colors.dart';
import 'package:flutter/material.dart';

class GetReadyModal extends ModalRoute<void> {
  String _text = 'Get Ready';
  int _start = 2;
  final BuildContext context;

  GetReadyModal({this.context});

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration(milliseconds: 500);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.card,
      color: MyColors.primaryColor,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Center(
        child: Text(
      _text,
      style: TextStyle(fontSize: 36, color: Colors.white),
    ));
  }

  Timer _timer;

  changeText() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          this.setState(() {
            _text = 'GO';
            _start--;
          });
        } else if (_start < 0) {
          timer.cancel();
          Navigator.of(context).pop();
        } else {
          this.setState(() {
            _text = '$_start';
            _start--;
          });
        }
      },
    );
  }

  @override
  void install() {
    super.install();
    changeText();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // You can add your own animations for the overlay content
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}
