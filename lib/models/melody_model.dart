import 'package:cloud_firestore/cloud_firestore.dart';

class Melody {
  final String id;
  final String name;
  final String description;
  final String audioUrl;
  final String authorId;
  final Timestamp timestamp;

  Melody(
      {this.id,
      this.name,
      this.description,
      this.audioUrl,
      this.authorId,
      this.timestamp});

  factory Melody.fromDoc(DocumentSnapshot doc) {
    return Melody(
        id: doc.documentID,
        name: doc['name'],
        description: doc['description'] ?? '',
        audioUrl: doc['audio_url'],
        authorId: doc['author_id'],
        timestamp: doc['timestamp']);
  }
}
