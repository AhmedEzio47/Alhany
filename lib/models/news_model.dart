import 'package:Alhany/app_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String contentUrl;
  final String text;
  final String thumbnail;
  final String type;
  final int duration;
  int likes;
  int comments;
  int shares;
  int views;
  final Timestamp timestamp;

  News(
      {this.id,
      this.contentUrl,
      this.text,
      this.thumbnail,
      this.duration,
      this.type,
      this.likes,
      this.comments,
      this.shares,
      this.views,
      this.timestamp});

  factory News.fromDoc(DocumentSnapshot doc) {
    return News(
        id: doc.id,
        text: doc.data()['text'],
        thumbnail: doc.data()['thumbnail'],
        contentUrl: AppUtil.urlFullyEncode(doc.data()['content_url']),
        type: doc.data()['type'],
        duration: doc.data()['duration'],
        likes: doc.data()['likes'],
        comments: doc.data()['comments'],
        shares: doc.data()['shares'],
        views: doc.data()['views'],
        timestamp: doc.data()['timestamp']);
  }
}
