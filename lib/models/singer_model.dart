import 'package:cloud_firestore/cloud_firestore.dart';

class Singer {
  final String id;
  final String name;
  final String imageUrl;
  final List search;

  Singer({this.id, this.name, this.imageUrl, this.search});

  factory Singer.fromDoc(DocumentSnapshot doc) {
    return Singer(id: doc.documentID, name: doc['name'], imageUrl: doc['image_url'], search: doc['search']);
  }
}
