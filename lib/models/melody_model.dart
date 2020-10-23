import 'package:cloud_firestore/cloud_firestore.dart';

class Melody {
  final String id;
  final String name;
  final String description;
  final String audioUrl;
  final Map levelUrls;
  final String imageUrl;
  final String authorId;
  final bool isSong;
  final String price;
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
      this.isSong,
      this.price,
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
        isSong: doc['is_song'],
        price: doc['price'],
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
      // levelUrls: {
      //   'do': map['do'],
      //   're': map['re'],
      //   'mi': map['mi'],
      //   'fa': map['fa'],
      //   'sol': map['sol'],
      //   'la': map['la'],
      //   'si': map['si']
      // },
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
      // 'do': this.levelUrls['do'] ?? null,
      // 're': this.levelUrls['re'] ?? null,
      // 'mi': this.levelUrls['mi'] ?? null,
      // 'fa': this.levelUrls['fa'] ?? null,
      // 'sol': this.levelUrls['sol'] ?? null,
      // 'la': this.levelUrls['la'] ?? null,
      // 'si': this.levelUrls['si'] ?? null,
    };
    return map;
  }
}
