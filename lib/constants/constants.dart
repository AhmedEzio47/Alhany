import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/widgets/music_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Constants
final firebaseAuth = FirebaseAuth.instance;
final firestore = Firestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final usersRef = firestore.collection('users');
final melodiesRef = firestore.collection('melodies');
final recordsRef = firestore.collection('records');
final chatsRef = firestore.collection('chats');

MusicPlayer musicPlayer;

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

AuthStatus authStatus = AuthStatus.NOT_DETERMINED;

class Constants {
  static String currentUserID;
  static User currentUser;
  static FirebaseUser currentFirebaseUser;

  static User startUser;

  static String currentMelodyLevel;
}
