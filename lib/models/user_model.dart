import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
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
        profileImageUrl: doc['profile_url'],
        email: doc['email'],
        description: doc['description'] ?? '',
        violations: doc['violations'],
        notificationsNumber: doc['notifications_number'],
        online: doc['online'],
        search: doc['search']);
  }
}
