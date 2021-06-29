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
  final List boughtSongs;
  final List boughtTracks;
  final List boughtMelodies;
  final dynamic online;

  User(
      {this.id,
      this.name,
      this.username,
      this.profileImageUrl,
      this.email,
      this.description,
      this.violations,
      this.boughtSongs,
      this.boughtTracks,
      this.boughtMelodies,
      this.notificationsNumber,
      this.online,
      this.search});

  factory User.fromDoc(DocumentSnapshot doc) {
    return User(
        id: doc.id,
        name: doc.data()['name'],
        username: doc.data()['username'],
        profileImageUrl: doc.data()['profile_url'],
        email: doc.data()['email'],
        description: doc.data()['description'] ?? '',
        violations: doc.data()['violations'],
        boughtSongs: doc.data()['bought_songs'],
        boughtTracks: doc.data()['bought_tracks'],
        boughtMelodies: doc.data()['bought_melodies'],
        notificationsNumber: doc.data()['notificationsNumber'],
        online: doc.data()['online'],
        search: doc.data()['search']);
  }
}
