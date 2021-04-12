import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String? id;
  final String? url;
  final String? thumbnailUrl;
  final String? singerId;
  final String? melodyId;
  final int? duration;
  int? likes;
  int? comments;
  int? shares;
  int? views;
  final Timestamp? timestamp;

  Record(
      { this.id,
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
        id: doc.id,
        url: doc.data()!['audio_url'],
        thumbnailUrl: doc.data()!['thumbnail_url'],
        singerId: doc.data()!['singer_id'],
        melodyId: doc.data()!['melody_id'],
        duration: doc.data()!['duration'],
        likes: doc.data()!['likes'],
        comments: doc.data()!['comments'],
        shares: doc.data()!['shares'],
        views: doc.data()!['views'],
        timestamp: doc.data()!['timestamp']);
  }
}
