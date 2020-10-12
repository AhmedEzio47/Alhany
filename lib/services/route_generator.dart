import 'package:dubsmash/pages/app_page.dart';
import 'package:dubsmash/pages/conversation.dart';
import 'package:dubsmash/pages/melody_page.dart';
import 'package:dubsmash/pages/password_reset.dart';
import 'package:dubsmash/pages/profile_page.dart';
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

      case '/profile-page':
        return MaterialPageRoute(
            builder: (_) => ProfilePage(
                  userId: args['user_id'],
                ));

      case '/password-reset':
        return MaterialPageRoute(builder: (_) => PasswordResetPage());

      case '/conversation':
        return MaterialPageRoute(
            builder: (_) => Conversation(
                  otherUid: args['other_uid'],
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
