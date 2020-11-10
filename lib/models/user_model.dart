import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final String email;
  final String description;
  final int violations;
  final int notificationsNumber;
  final List search;
  final dynamic online;

  User(
      {this.id,
      this.name,
      this.username,
      this.profileImageUrl,
      this.email,
      this.description,
      this.violations,
      this.notificationsNumber,
      this.online,
      this.search});

  factory User.fromDoc(DocumentSnapshot doc) {
    return User(
        id: doc.documentID,
        name: doc['name'],
        username: doc['username'],
        profileImageUrl: doc['profile_url'],
        email: doc['email'],
        description: doc['description'] ?? '',
        violations: doc['violations'],
        notificationsNumber: doc['notificationsNumber'],
        online: doc['online'],
        search: doc['search']);
  }
}
