import 'package:cloud_firestore/cloud_firestore.dart';

class Melody {
  final String id;
  final String name;
  final String description;
  final String audioUrl;
  final Map levelUrls;
  final String imageUrl;
  final String authorId;
  final String singer;
  final bool isSong;
  final String price;
  final int views;
  final List search;
  final Timestamp timestamp;

  Melody(
      {this.id,
      this.name,
      this.description,
      this.audioUrl,
      this.levelUrls,
      this.imageUrl,
      this.authorId,
      this.singer,
      this.isSong,
      this.price,
      this.views,
      this.search,
      this.timestamp});

  factory Melody.fromDoc(DocumentSnapshot doc) {
    return Melody(
        id: doc.documentID,
        name: doc['name'],
        description: doc['description'] ?? '',
        audioUrl: doc['audio_url'],
        levelUrls: doc['level_urls'],
        imageUrl: doc['image_url'],
        authorId: doc['author_id'],
        singer: doc['singer'],
        isSong: doc['is_song'],
        price: doc['price'],
        views: doc['views'],
        search: doc['search'],
        timestamp: doc['timestamp']);
  }

  factory Melody.fromMap(Map<String, dynamic> map) {
    return Melody(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      authorId: map['author_id'],
      audioUrl: map['audio_url'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': this.id,
      'name': this.name,
      'description': this.description,
      'author_id': this.authorId,
      'audio_url': this.audioUrl,
      'image_url': this.imageUrl,
    };
    return map;
  }
}
