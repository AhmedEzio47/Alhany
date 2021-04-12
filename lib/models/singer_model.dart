import 'package:cloud_firestore/cloud_firestore.dart';

class Singer {
  final String? id;
  final String? name;
  final String? category;
  final String? imageUrl;
  final String? coverUrl;
  final int? songs;
  final int? melodies;
  final List? search;

  Singer(
      { this.id,
       this.name,
       this.category,
       this.imageUrl,
       this.coverUrl,
       this.songs,
       this.melodies,
       this.search});

  factory Singer.fromDoc(DocumentSnapshot doc) {
    return Singer(
        id: doc.id,
        name: doc.data()!['name'],
        category: doc.data()!['category'],
        imageUrl: doc.data()!['image_url'],
        coverUrl: doc.data()!['cover_url'],
        songs: doc.data()!['songs'],
        melodies: doc.data()!['melodies'],
        search: doc.data()!['search']);
  }
}
