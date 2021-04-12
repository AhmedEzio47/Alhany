import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String? id;
  final String? commenterID;
  final String? text;
  int? likes;
  int? replies;
  final Timestamp? timestamp;

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
      id: doc.id,
      commenterID: doc.data()!['commenter'],
      text: doc.data()!['text'],
      likes: doc.data()!['likes'],
      replies: doc.data()!['replies'],
      timestamp: doc.data()!['timestamp'],
    );
  }
}
