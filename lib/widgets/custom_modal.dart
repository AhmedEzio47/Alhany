import 'package:dubsmash/constants/strings.dart';
import 'package:flutter/material.dart';

class CustomModal extends ModalRoute<void> {
  final Widget child;
  final Function onWillPop;

  BuildContext _context;
  CustomModal({this.onWillPop, this.child});
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
    _context = context;

    // This makes sure that text and other content follows the material style
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Material(
        type: MaterialType.transparency,
        // make sure that the overlay content is not cut off
        child: SafeArea(
          child: _buildOverlayContent(context),
        ),
      ),
    );
  }

  Future<bool> onBackPressed() {
    if (onWillPop != null) {
      onWillPop();
    } else {
      Navigator.of(_context).pop();
    }
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Center(child: child);
  }

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
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
