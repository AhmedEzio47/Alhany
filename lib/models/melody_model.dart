import 'package:cloud_firestore/cloud_firestore.dart';

class Melody {
  final String id;
  final String name;
  final String description;
  final String audioUrl;
  final String imageUrl;
  final String authorId;
  final bool isSong;
  final Timestamp timestamp;

  Melody(
      {this.id,
      this.name,
      this.description,
      this.audioUrl,
      this.imageUrl,
      this.authorId,
      this.isSong,
      this.timestamp});

  factory Melody.fromDoc(DocumentSnapshot doc) {
    return Melody(
        id: doc.documentID,
        name: doc['name'],
        description: doc['description'] ?? '',
        audioUrl: doc['audio_url'],
        imageUrl: doc['image_url'],
        authorId: doc['author_id'],
        isSong: doc['is_song'],
        timestamp: doc['timestamp']);
  }
}
