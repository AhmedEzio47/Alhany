import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/message_model.dart';
import 'package:dubsmash/models/record.dart';
import 'package:dubsmash/models/singer_model.dart';
import 'package:dubsmash/models/user_model.dart';

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
    QuerySnapshot userDocSnapshot = await usersRef.where('email', isEqualTo: email).getDocuments();
    if (userDocSnapshot.documents.length != 0) {
      return User.fromDoc(userDocSnapshot.documents[0]);
    }
    return User();
  }

  static Future<Melody> getMelodyWithId(String melodyId) async {
    DocumentSnapshot melodyDocSnapshot = await melodiesRef?.document(melodyId)?.get();
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
      'followers': 0,
      'following': 0,
      'search': search
    };

    await usersRef.document(id).setData(userMap);
  }

  static Future<List<Melody>> getMelodies() async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> melodies = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getNextMelodies(Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Melody> melodies = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static searchMelodies(String text) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .where('search', arrayContains: text)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> melodies = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getFavourites() async {
    QuerySnapshot melodiesSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('favourites')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    List<Melody> melodies = [];

    for (DocumentSnapshot doc in melodiesSnapshot.documents) {
      Melody melody = await getMelodyWithId(doc.documentID);
      melodies.add(melody);
    }

    return melodies;
  }

  static Future<List<Melody>> getSongs() async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> songs = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static Future<List<Melody>> getNextSongs(Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Melody> songs = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static searchSongs(String text) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .where('search', arrayContains: text)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> songs = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static Future<List<Record>> getRecords() async {
    QuerySnapshot recordsSnapshot = await recordsRef.orderBy('timestamp', descending: true).getDocuments();
    List<Record> records = recordsSnapshot.documents.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static Future<List<Record>> getRecordsByMelody(String melodyId) async {
    QuerySnapshot recordsSnapshot =
        await recordsRef.where('melody_id', isEqualTo: melodyId).orderBy('timestamp', descending: true).getDocuments();
    List<Record> records = recordsSnapshot.documents.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static Future<List<Record>> getNextRecords(Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Record> records = recordsSnapshot.documents.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static getUserRecords(String userId) async {
    QuerySnapshot recordsSnapshot =
        await recordsRef.where('singer_id', isEqualTo: userId).orderBy('timestamp', descending: true).getDocuments();
    List<Record> records = recordsSnapshot.documents.map((doc) => Record.fromDoc(doc)).toList();
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
    await usersRef.document(Constants.currentUserID).collection('favourites').document(melodyId).delete();
  }

  static saveRecord(String melodyId, String recordId, String url) async {
    await recordsRef.document(recordId).setData({
      'audio_url': url,
      'singer_id': Constants.currentUserID,
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

  static unfollowUser(String userId) async {
    await usersRef.document(Constants.currentUserID).collection('following').document(userId).delete();

    await usersRef.document(userId).collection('followers').document(Constants.currentUserID).delete();

    //Store/update user locally
    User user = await DatabaseService.getUserWithId(userId);

    await usersRef.document(Constants.currentUserID).updateData({'following': FieldValue.increment(-1)});

    await usersRef.document(userId).updateData({'followers': FieldValue.increment(-1)});
  }

  static followUser(String userId) async {
    await usersRef.document(userId).collection('followers').document(Constants.currentUserID).setData({
      'timestamp': FieldValue.serverTimestamp(),
    });

    await usersRef.document(Constants.currentUserID).collection('following').document(userId).setData({
      'timestamp': FieldValue.serverTimestamp(),
    });

    //Increment current user following and other user followers
    await usersRef.document(Constants.currentUserID).updateData({'following': FieldValue.increment(1)});

    await usersRef.document(userId).updateData({'followers': FieldValue.increment(1)});
  }

  static sendMessage(String otherUserId, String type, String message) async {
    await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });

    await chatsRef
        .document(otherUserId)
        .collection('conversations')
        .document(Constants.currentUserID)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });
  }

  static Future<List<Message>> getMessages(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<Message> messages = msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static Future<List<Message>> getPrevMessages(Timestamp firstVisibleGameSnapShot, String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([firstVisibleGameSnapShot])
        .limit(20)
        .getDocuments();
    List<Message> messages = msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static getLastMessage(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .getDocuments();
    List<Message> messages = msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    if (messages.length == 0)
      return Message(message: 'Say hi to your new friend!', type: 'text', sender: otherUserId, timestamp: null);
    return messages[0];
  }

  static makeUserOnline() async {
    await usersRef.document(Constants.currentUserID).updateData({'online': 'online'});
  }

  static makeUserOffline() async {
    await usersRef.document(Constants.currentUserID).updateData({'online': FieldValue.serverTimestamp()});
  }

  static Future<List<String>> getChats() async {
    QuerySnapshot chatsSnapshot =
        await chatsRef.document(Constants.currentUserID).collection('conversations').getDocuments();

    List<String> chattersIds = [];
    for (DocumentSnapshot doc in chatsSnapshot.documents) {
      chattersIds.add(doc.documentID);
    }
    return chattersIds;
  }

  static removeNotification(String receiverId, String objectId, String type) async {
    QuerySnapshot snapshot = await usersRef
        .document(receiverId)
        .collection('notifications')
        .where('sender', isEqualTo: Constants.currentUserID)
        .where('type', isEqualTo: type)
        .where('object_id', isEqualTo: objectId)
        .getDocuments();

    if (snapshot.documents.length > 0) {
      await usersRef
          .document(receiverId)
          .collection('notifications')
          .document(snapshot.documents[0].documentID)
          .delete();

      await usersRef.document(receiverId).updateData({'notificationsNumber': FieldValue.increment(-1)});
    }
  }

  static incrementMelodyViews(String melodyId) async {
    await melodiesRef.document(melodyId).updateData({'views': FieldValue.increment(1)});
  }

  static Future<List<Singer>> getSingers() async {
    QuerySnapshot singersSnapshot = await singersRef.orderBy('name', descending: false).getDocuments();
    List<Singer> singers = singersSnapshot.documents.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Melody>> getSongsBySingerName(String singerName) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .where('singer', isEqualTo: singerName)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> songs = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }
}
