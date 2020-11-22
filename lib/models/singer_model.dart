import 'package:cloud_firestore/cloud_firestore.dart';

class Singer {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final String coverUrl;
  final int songs;
  final int melodies;
  final List search;

  Singer(
      {this.id,
      this.name,
      this.category,
      this.imageUrl,
      this.coverUrl,
      this.songs,
      this.melodies,
      this.search});

  factory Singer.fromDoc(DocumentSnapshot doc) {
    return Singer(
        id: doc.documentID,
        name: doc['name'],
        category: doc['category'],
        imageUrl: doc['image_url'],
        coverUrl: doc['cover_url'],
        songs: doc['songs'],
        melodies: doc['melodies'],
        search: doc['search']);
  }
}
