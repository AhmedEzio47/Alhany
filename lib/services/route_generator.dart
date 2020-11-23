import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/pages/add_singer.dart';
import 'package:Alhany/pages/app_page.dart';
import 'package:Alhany/pages/category_page.dart';
import 'package:Alhany/pages/chats.dart';
import 'package:Alhany/pages/comment_page.dart';
import 'package:Alhany/pages/conversation.dart';
import 'package:Alhany/pages/downloads.dart';
import 'package:Alhany/pages/email_change.dart';
import 'package:Alhany/pages/lyrics_editor.dart';
import 'package:Alhany/pages/melody_page.dart';
import 'package:Alhany/pages/news_page.dart';
import 'package:Alhany/pages/password_reset.dart';
import 'package:Alhany/pages/payment_home.dart';
import 'package:Alhany/pages/profile_page.dart';
import 'package:Alhany/pages/post_fullscreen.dart';
import 'package:Alhany/pages/record_page.dart';
import 'package:Alhany/pages/root.dart';
import 'package:Alhany/pages/search_page.dart';
import 'package:Alhany/pages/singer_page.dart';
import 'package:Alhany/pages/singers_page.dart';
import 'package:Alhany/pages/slide_images.dart';
import 'package:Alhany/pages/songs_page.dart';
import 'package:Alhany/pages/upload_mulit_level_melody.dart';
import 'package:Alhany/pages/upload_news.dart';
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
                  singer: args != null ? args['singer'] : null,
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
        return MaterialPageRoute(
            builder: (_) => LyricsEditor(
                  melody: args['melody'],
                ));

      case '/record-page':
        Constants.currentRoute = settings.name;
        return MaterialPageRoute(
            builder: (_) => RecordPage(
                  record: args['record'],
                  isVideoVisible: args['is_video_visible'],
                ));

      case '/news-page':
        Constants.currentRoute = settings.name;
        return MaterialPageRoute(
            builder: (_) => NewsPage(
                  news: args['news'],
                ));

      case '/post-fullscreen':
        return MaterialPageRoute(
            builder: (_) => PostFullscreen(
                  record: args['record'],
                  news: args['news'],
                  singer: args['singer'],
                  melody: args['melody'],
                ));

      case '/comment-page':
        Constants.currentRoute = settings.name;
        return MaterialPageRoute(
            builder: (_) => CommentPage(
                  record: args['record'],
                  news: args['news'],
                  comment: args['comment'],
                ));

      case '/singer-page':
        return MaterialPageRoute(
            builder: (_) => SingerPage(
                  singer: args['singer'],
                  dataType: args['data_type'],
                ));

      case '/singers-page':
        return MaterialPageRoute(builder: (_) => SingersPage());

      case '/category-page':
        return MaterialPageRoute(
            builder: (_) => CategoryPage(
                  category: args['category'],
                ));

      case '/search-page':
        return MaterialPageRoute(builder: (_) => SearchPage());

      case '/upload-news':
        return MaterialPageRoute(builder: (_) => UploadNews());

      case '/payment-home':
        return MaterialPageRoute(
            builder: (_) => PaymentHomePage(
                  amount: args['amount'],
                ));

      case '/slide-images':
        return MaterialPageRoute(builder: (_) => SlideImages());

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
