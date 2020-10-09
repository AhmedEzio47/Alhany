import 'package:dubsmash/pages/app_page.dart';
import 'package:dubsmash/pages/melody_page.dart';
import 'package:dubsmash/pages/root.dart';
import 'package:dubsmash/pages/welcome_page.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final Map args = settings.arguments as Map;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => RootPage());

      case '/app-page':
        return MaterialPageRoute(builder: (_) => AppPage());

      case '/welcome-page':
        return MaterialPageRoute(builder: (_) => WelcomePage());

      case '/melody-page':
        return MaterialPageRoute(
            builder: (_) => MelodyPage(
                  melody: args['melody'],
                ));

      default:
        // If there is no such named route in the switch statement, e.g. /third
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('ERROR'),
        ),
      );
    });
  }
}
