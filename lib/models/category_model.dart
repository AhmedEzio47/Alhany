import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String? id;
  final String? name;
  final int? order;
  final List? search;

  Category({ this.id,  this.name,  this.order,  this.search});

  factory Category.fromDoc(DocumentSnapshot doc) {
    return Category(
        id: doc.id,
        name: doc.data()!['name'],
        order: doc.data()!['order'],
        search: doc.data()!['search']);
  }
}
