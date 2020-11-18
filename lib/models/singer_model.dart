import 'package:cloud_firestore/cloud_firestore.dart';

class Singer {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final String coverUrl;
  final List search;

  Singer(
      {this.id,
      this.name,
      this.category,
      this.imageUrl,
      this.coverUrl,
      this.search});

  factory Singer.fromDoc(DocumentSnapshot doc) {
    return Singer(
        id: doc.documentID,
        name: doc['name'],
        category: doc['category'],
        imageUrl: doc['image_url'],
        coverUrl: doc['cover_url'],
        search: doc['search']);
  }
}
