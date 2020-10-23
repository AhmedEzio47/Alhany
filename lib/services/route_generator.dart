import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/pages/app_page.dart';
import 'package:dubsmash/pages/chats.dart';
import 'package:dubsmash/pages/conversation.dart';
import 'package:dubsmash/pages/downloads.dart';
import 'package:dubsmash/pages/email_change.dart';
import 'package:dubsmash/pages/melody_page.dart';
import 'package:dubsmash/pages/password_reset.dart';
import 'package:dubsmash/pages/profile_page.dart';
import 'package:dubsmash/pages/root.dart';
import 'package:dubsmash/pages/upload_melodies.dart';
import 'package:dubsmash/pages/upload_songs.dart';
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

      case '/chats':
        return MaterialPageRoute(builder: (_) => Chats());

      case '/upload-melodies':
        return MaterialPageRoute(builder: (_) => UploadMelodies());

      case '/upload-songs':
        return MaterialPageRoute(builder: (_) => UploadSongs());

      case '/change-email':
        return MaterialPageRoute(builder: (_) => EmailChangePage());

      case '/downloads':
        Constants.currentRoute = settings.name;
        return MaterialPageRoute(builder: (_) => DownloadsPage());

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
