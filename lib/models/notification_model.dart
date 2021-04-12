import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String? id;
  final String? title;
  final String? body;
  final String? icon;
  final bool? seen;
  final Timestamp? timestamp;
  final String? sender;
  final String? objectId;
  final String? type;

  Notification(
      { this.id,
       this.title,
       this.body,
       this.icon,
       this.seen,
       this.timestamp,
       this.sender,
       this.objectId,
       this.type});

  factory Notification.fromDoc(DocumentSnapshot doc) {
    return Notification(
        id: doc.id,
        title: doc.data()!['title'],
        body: doc.data()!['body'],
        icon: doc.data()!['icon'],
        seen: doc.data()!['seen'],
        timestamp: doc.data()!['timestamp'],
        sender: doc.data()!['sender'],
        objectId: doc.data()!['object_id'],
        type: doc.data()!['type']);
  }
}
