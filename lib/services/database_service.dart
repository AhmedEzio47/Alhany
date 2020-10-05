import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:flutter/material.dart';

import '../app_util.dart';

class DatabaseService {
  static Future<User> getUserWithId(String userId) async {
    DocumentSnapshot userDocSnapshot = await usersRef?.document(userId)?.get();
    if (userDocSnapshot.exists) {
      return User.fromDoc(userDocSnapshot);
    }
    return User();
  }

  static addUserToDatabase(String id, String email, String name) async {
    List search = searchList(name);
    Map<String, dynamic> userMap = {
      'name': name,
      'email': email,
      'description': 'Write something about yourself',
      'notificationsNumber': 0,
      'search': search
    };

    await usersRef.document(id).setData(userMap);
  }

  static Future<List<Melody>> getMelodies() async {
    QuerySnapshot melodiesSnapshot =
        await melodiesRef.orderBy('timestamp', descending: true).getDocuments();
    List<Melody> melodies =
        melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }
}
