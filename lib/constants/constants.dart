import 'package:Alhany/models/user_model.dart' as user_model;
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Firebase Constants
final firebaseAuth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final usersRef = firestore.collection('users');
final melodiesRef = firestore.collection('melodies');
final recordsRef = firestore.collection('records');
final chatsRef = firestore.collection('chats');
final singersRef = firestore.collection('singers');
final categoriesRef = firestore.collection('categories');
final newsRef = firestore.collection('news');
final slideImagesRef = firestore.collection('slide_images');
List<CameraDescription>? cameras;
Widget? musicPlayer;

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

AuthStatus authStatus = AuthStatus.NOT_DETERMINED;

class Constants {
  static String? currentUserID;
  static user_model.User? currentUser;
  static User? currentFirebaseUser;

  static user_model.User? starUser;
  static bool isAdmin = false;

  static String? currentMelodyLevel;

  static String? currentRoute;
  static List<String> routeStack = [];

  static String? language;

  static bool? isFacebookOrGoogleUser;

  static double musicVolume = 0.9;
  static double voiceVolume = 7;

  static int endPositionOffsetInMilliSeconds = 600;

  static bool ongoingEncoding = false;
}
