import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String contentUrl;
  final String title;
  final String text;
  final String type;
  final int duration;
  int likes;
  int comments;
  int shares;
  final Timestamp timestamp;

  News(
      {this.id,
      this.contentUrl,
      this.title,
      this.text,
      this.duration,
      this.type,
      this.likes,
      this.comments,
      this.shares,
      this.timestamp});

  factory News.fromDoc(DocumentSnapshot doc) {
    return News(
        id: doc.documentID,
        title: doc['title'],
        text: doc['text'],
        contentUrl: doc['content_url'],
        type: doc['type'],
        duration: doc['duration'],
        likes: doc['likes'],
        comments: doc['comments'],
        shares: doc['shares'],
        timestamp: doc['timestamp']);
  }
}
