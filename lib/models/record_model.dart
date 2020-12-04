import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String singerId;
  final String melodyId;
  final int duration;
  int likes;
  int comments;
  int shares;
  int views;
  final Timestamp timestamp;

  Record(
      {this.id,
      this.url,
      this.thumbnailUrl,
      this.singerId,
      this.melodyId,
      this.duration,
      this.likes,
      this.comments,
      this.shares,
      this.views,
      this.timestamp});

  factory Record.fromDoc(DocumentSnapshot doc) {
    return Record(
        id: doc.documentID,
        url: doc['audio_url'],
        thumbnailUrl: doc['thumbnail_url'],
        singerId: doc['singer_id'],
        melodyId: doc['melody_id'],
        duration: doc['duration'],
        likes: doc['likes'],
        comments: doc['comments'],
        shares: doc['shares'],
        views: doc['views'],
        timestamp: doc['timestamp']);
  }
}
