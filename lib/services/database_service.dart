import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/record.dart';
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

  static Future<User> getUserWithEmail(String email) async {
    QuerySnapshot userDocSnapshot =
        await usersRef.where('email', isEqualTo: email).getDocuments();
    if (userDocSnapshot.documents.length != 0) {
      return User.fromDoc(userDocSnapshot.documents[0]);
    }
    return User();
  }

  static Future<Melody> getMelodyWithId(String melodyId) async {
    DocumentSnapshot melodyDocSnapshot =
        await melodiesRef?.document(melodyId)?.get();
    if (melodyDocSnapshot.exists) {
      return Melody.fromDoc(melodyDocSnapshot);
    }
    return Melody();
  }

  static addUserToDatabase(String id, String email, String name) async {
    List search = searchList(name);
    Map<String, dynamic> userMap = {
      'name': name ?? 'John Doe',
      'email': email,
      'description': 'Write something about yourself',
      'notificationsNumber': 0,
      'search': search
    };

    await usersRef.document(id).setData(userMap);
  }

  static Future<List<Melody>> getMelodies() async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> melodies =
        melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getSongs() async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> melodies =
        melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Record>> getRecords() async {
    QuerySnapshot recordsSnapshot =
        await recordsRef.orderBy('timestamp', descending: true).getDocuments();
    List<Record> records =
        recordsSnapshot.documents.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static Future addMelodyToFavourites(String melodyId) async {
    await usersRef
        .document(Constants.currentUserID)
        .collection('favourites')
        .document(melodyId)
        .setData({'timestamp': FieldValue.serverTimestamp()});
  }

  static Future deleteMelodyFromFavourites(String melodyId) async {
    await usersRef
        .document(Constants.currentUserID)
        .collection('favourites')
        .document(melodyId)
        .delete();
  }

  static saveRecord(String melodyId, String recordId, String url) async {
    await recordsRef.document(recordId).setData({
      'audio_url': url,
      'singer_id': Constants.currentUserID,
      'melody_id': melodyId,
      'timestamp': FieldValue.serverTimestamp()
    });

    await melodiesRef
        .document(melodyId)
        .collection('records')
        .document(recordId)
        .setData({
      'audio_url': url,
      'singer_id': Constants.currentUserID,
      'timestamp': FieldValue.serverTimestamp()
    });

    await usersRef
        .document(Constants.currentUserID)
        .collection('records')
        .document(recordId)
        .setData({
      'audio_url': url,
      'melody_id': melodyId,
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  static Future<String> checkForDuplicateRecords(String melodyId) async {
    QuerySnapshot snapshot = await recordsRef
        .where('melody_id', isEqualTo: melodyId)
        .where('singer_id', isEqualTo: Constants.currentUserID)
        .getDocuments();
    if (snapshot.documents.length > 0) {
      return snapshot.documents[0].documentID;
    }
    return null;
  }
}
