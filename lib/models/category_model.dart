import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final List search;

  Category({this.id, this.name, this.search});

  factory Category.fromDoc(DocumentSnapshot doc) {
    return Category(
        id: doc.id, name: doc.data()['name'], search: doc.data()['search']);
  }
}
