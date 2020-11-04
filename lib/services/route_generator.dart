import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/pages/add_singer.dart';
import 'package:Alhany/pages/app_page.dart';
import 'package:Alhany/pages/chats.dart';
import 'package:Alhany/pages/comment_page.dart';
import 'package:Alhany/pages/conversation.dart';
import 'package:Alhany/pages/downloads.dart';
import 'package:Alhany/pages/email_change.dart';
import 'package:Alhany/pages/lyrics_editor.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/pages/password_reset.dart';
import 'package:Alhany/pages/profile_page.dart';
import 'package:Alhany/pages/record_fullscreen.dart';
import 'package:Alhany/pages/record_page.dart';
import 'package:Alhany/pages/root.dart';
import 'package:Alhany/pages/songs_page.dart';
import 'package:Alhany/pages/upload_mulit_level_melody.dart';
import 'package:Alhany/pages/upload_single_level_melody.dart';
import 'package:Alhany/pages/upload_songs.dart';
import 'package:Alhany/pages/welcome_page.dart';
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
                  type: args['type'],
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

      case '/upload-multi-level-melody':
        return MaterialPageRoute(builder: (_) => UploadMultiLevelMelody());

      case '/upload-single-level-melody':
        return MaterialPageRoute(builder: (_) => UploadSingleLevelMelody());

      case '/upload-songs':
        return MaterialPageRoute(
            builder: (_) => UploadSongs(
                  singer: args['singer'],
                ));

      case '/change-email':
        return MaterialPageRoute(builder: (_) => EmailChangePage());

      case '/downloads':
        Constants.currentRoute = settings.name;
        return MaterialPageRoute(builder: (_) => DownloadsPage());

      case '/add-singer':
        return MaterialPageRoute(builder: (_) => AddSingerPage());
      case '/songs-page':
        return MaterialPageRoute(
            builder: (_) => SongsPage(
                  singer: args['singer'],
                ));
      case '/lyrics-editor':
        return MaterialPageRoute(builder: (_) => LyricsEditor());

      case '/record-page':
        Constants.currentRoute = settings.name;
        return MaterialPageRoute(
            builder: (_) => RecordPage(
                  record: args['record'],
                ));

      case '/record-fullscreen':
        return MaterialPageRoute(
            builder: (_) => RecordFullscreen(
                  record: args['record'],
                  singer: args['singer'],
                ));

      case '/comment-page':
        Constants.currentRoute = settings.name;
        return MaterialPageRoute(
            builder: (_) => CommentPage(
                  record: args['record'],
                  comment: args['comment'],
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
