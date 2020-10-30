import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String commenterID;
  final String text;
  int likes;
  int replies;
  final Timestamp timestamp;

  Comment({
    this.id,
    this.commenterID,
    this.text,
    this.likes,
    this.replies,
    this.timestamp,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    return Comment(
      id: doc.documentID,
      commenterID: doc['commenter'],
      text: doc['text'],
      likes: doc['likes'],
      replies: doc['replies'],
      timestamp: doc['timestamp'],
    );
  }
}
