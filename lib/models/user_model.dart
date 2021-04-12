import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  final String? name;
  final String? username;
  final String? profileImageUrl;
  final String? email;
  final String? description;
  final int? violations;
  final int? notificationsNumber;
  final List? search;
  final dynamic? online;

  User(
      { this.id,
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
        id: doc.id,
        name: doc.data()!['name'],
        username: doc.data()!['username'],
        profileImageUrl: doc.data()!['profile_url'],
        email: doc.data()!['email'],
        description: doc.data()!['description'] ?? '',
        violations: doc.data()!['violations'],
        notificationsNumber: doc.data()!['notificationsNumber'],
        online: doc.data()!['online'],
        search: doc.data()!['search']);
  }
}
