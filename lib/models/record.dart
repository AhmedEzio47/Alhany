import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String id;
  final String audioUrl;
  final String singerId;
  final String melodyId;
  final duration;
  final Timestamp timestamp;

  Record({this.id, this.audioUrl, this.singerId, this.melodyId, this.duration, this.timestamp});

  factory Record.fromDoc(DocumentSnapshot doc) {
    return Record(
        id: doc.documentID,
        audioUrl: doc['audio_url'],
        singerId: doc['singer_id'],
        melodyId: doc['melody_id'],
        duration: doc['duration'],
        timestamp: doc['timestamp']);
  }
}
