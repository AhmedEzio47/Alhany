import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/models/category_model.dart';
import 'package:Alhany/models/comment_model.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/message_model.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/notification_model.dart' as notification;
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/models/slide_image.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_util.dart';

class DatabaseService {
  static Future<User> getUserWithId(String userId) async {
    DocumentSnapshot userDocSnapshot = await usersRef?.doc(userId)?.get();
    if (userDocSnapshot.exists) {
      return User.fromDoc(userDocSnapshot);
    }
    return User();
  }

  static Future<User> getUserWithEmail(String email) async {
    QuerySnapshot userDocSnapshot =
        await usersRef.where('email', isEqualTo: email).get();
    if (userDocSnapshot.docs.length != 0) {
      return User.fromDoc(userDocSnapshot.docs[0]);
    }
    return User();
  }

  static Future<Melody> getMelodyWithId(String melodyId) async {
    DocumentSnapshot melodyDocSnapshot =
        await melodiesRef?.doc(melodyId)?.get();
    if (melodyDocSnapshot.exists) {
      return Melody.fromDoc(melodyDocSnapshot);
    }
    return Melody();
  }

  static addUserToDatabase(
      String id, String email, String name, String username) async {
    List search = searchList(name);
    Map<String, dynamic> userMap = {
      'name': name ?? 'John Doe',
      'username': username,
      'email': email,
      'description': 'Write something about yourself',
      'notificationsNumber': 0,
      'followers': 0,
      'following': 0,
      'search': search
    };

    await usersRef.doc(id).set(userMap);
  }

  static Future<List<Melody>> getMelodies() async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> melodies =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getStarMelodies() async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .where('author_id', isEqualTo: Constants.startUser.id)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> melodies =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getNextMelodies(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Melody> melodies =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static searchMelodies(String text) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .where('search', arrayContains: text)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> melodies =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getFavourites() async {
    QuerySnapshot melodiesSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('favourites')
        .orderBy('timestamp', descending: true)
        .get();

    List<Melody> melodies = [];

    for (DocumentSnapshot doc in melodiesSnapshot.docs) {
      Melody melody = await getMelodyWithId(doc.id);
      melodies.add(melody);
    }

    return melodies;
  }

  static Future<List<Melody>> getSongs() async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> songs =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static Future<List<Melody>> getNextSongs(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Melody> songs =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static searchSongs(String text) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .where('search', arrayContains: text)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> songs =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static searchSingers(String text) async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('search', arrayContains: text)
        .limit(20)
        .orderBy('name', descending: false)
        .get();
    List<Singer> singers =
        singersSnapshot.docs.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Record>> getRecords() async {
    QuerySnapshot recordsSnapshot =
        await recordsRef.limit(20).orderBy('timestamp', descending: true).get();
    List<Record> records =
        recordsSnapshot.docs.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static Future<List<Record>> getRecordsByMelody(String melodyId) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .where('melody_id', isEqualTo: melodyId)
        .orderBy('timestamp', descending: true)
        .get();
    List<Record> records =
        recordsSnapshot.docs.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static Future<List<Record>> getNextRecords(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Record> records =
        recordsSnapshot.docs.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static Future<Record> getNextRecord(Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(1)
        .get();
    List<Record> records =
        recordsSnapshot.docs.map((doc) => Record.fromDoc(doc)).toList();
    return records.length > 0 ? records[0] : null;
  }

  static Future<Record> getPrevRecord(Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .orderBy('timestamp', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(1)
        .get();
    List<Record> records =
        recordsSnapshot.docs.map((doc) => Record.fromDoc(doc)).toList();
    return records.length > 0 ? records[0] : null;
  }

  static getUserRecords(String userId) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .where('singer_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    List<Record> records =
        recordsSnapshot.docs.map((doc) => Record.fromDoc(doc)).toList();
    return records;
  }

  static Future addMelodyToFavourites(String melodyId) async {
    await usersRef
        .doc(Constants.currentUserID)
        .collection('favourites')
        .doc(melodyId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  static Future deleteMelodyFromFavourites(String melodyId) async {
    await usersRef
        .doc(Constants.currentUserID)
        .collection('favourites')
        .doc(melodyId)
        .delete();
  }

  static submitRecord(String melodyId, String recordId, String url,
      String thumbnailUrl, int duration) async {
    await recordsRef.doc(recordId).set({
      'audio_url': url,
      'thumbnail_url': thumbnailUrl,
      'singer_id': Constants.currentUserID,
      'melody_id': melodyId,
      'duration': duration,
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  static Future<String> checkForDuplicateRecords(String melodyId) async {
    QuerySnapshot snapshot = await recordsRef
        .where('melody_id', isEqualTo: melodyId)
        .where('singer_id', isEqualTo: Constants.currentUserID)
        .get();
    if (snapshot.docs.length > 0) {
      return snapshot.docs[0].id;
    }
    return null;
  }

  static unfollowUser(String userId) async {
    await usersRef
        .doc(Constants.currentUserID)
        .collection('following')
        .doc(userId)
        .delete();

    await usersRef
        .doc(userId)
        .collection('followers')
        .doc(Constants.currentUserID)
        .delete();

    //Store/update user locally
    User user = await DatabaseService.getUserWithId(userId);

    await usersRef
        .doc(Constants.currentUserID)
        .update({'following': FieldValue.increment(-1)});

    await usersRef.doc(userId).update({'followers': FieldValue.increment(-1)});
  }

  static followUser(String userId) async {
    await usersRef
        .doc(userId)
        .collection('followers')
        .doc(Constants.currentUserID)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    await usersRef
        .doc(Constants.currentUserID)
        .collection('following')
        .doc(userId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    //Increment current user following and other user followers
    await usersRef
        .doc(Constants.currentUserID)
        .update({'following': FieldValue.increment(1)});

    await usersRef.doc(userId).update({'followers': FieldValue.increment(1)});
  }

  static sendMessage(String otherUserId, String type, String message) async {
    await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });

    await chatsRef
        .doc(otherUserId)
        .collection('conversations')
        .doc(Constants.currentUserID)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });

    await chatsRef
        .doc(otherUserId)
        .collection('conversations')
        .doc(Constants.currentUserID)
        .set({
      'last_message_timestamp': FieldValue.serverTimestamp(),
    });

    await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .set({
      'last_message_timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Message>> getMessages(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static Future<List<Message>> getPrevMessages(
      Timestamp firstVisibleGameSnapShot, String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([firstVisibleGameSnapShot])
        .limit(20)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static getLastMessage(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    if (messages.length == 0)
      return Message(
          message: 'Say hi to your new friend!',
          type: 'text',
          sender: otherUserId,
          timestamp: null);
    return messages[0];
  }

  static makeUserOnline() async {
    await usersRef.doc(Constants.currentUserID).update({'online': 'online'});
  }

  static makeUserOffline() async {
    await usersRef
        .doc(Constants.currentUserID)
        .update({'online': FieldValue.serverTimestamp()});
  }

  static Future<List<String>> getChats() async {
    QuerySnapshot chatsSnapshot = await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .get();

    List<String> chattersIds = [];
    for (DocumentSnapshot doc in chatsSnapshot.docs) {
      chattersIds.add(doc.id);
    }
    return chattersIds;
  }

  static removeNotification(
      String receiverId, String objectId, String type) async {
    QuerySnapshot snapshot = await usersRef
        .doc(receiverId)
        .collection('notifications')
        .where('sender', isEqualTo: Constants.currentUserID)
        .where('type', isEqualTo: type)
        .where('object_id', isEqualTo: objectId)
        .get();

    if (snapshot.docs.length > 0) {
      await usersRef
          .doc(receiverId)
          .collection('notifications')
          .doc(snapshot.docs[0].id)
          .delete();

      await usersRef
          .doc(receiverId)
          .update({'notificationsNumber': FieldValue.increment(-1)});
    }
  }

  static incrementMelodyViews(String melodyId) async {
    await melodiesRef.doc(melodyId).update({'views': FieldValue.increment(1)});
  }

  static incrementRecordViews(String recordId) async {
    await recordsRef.doc(recordId).update({'views': FieldValue.increment(1)});
  }

  static incrementNewsViews(String newsId) async {
    await newsRef.doc(newsId).update({'views': FieldValue.increment(1)});
  }

  static Future<List<Singer>> getSingers() async {
    QuerySnapshot singersSnapshot =
        await singersRef.orderBy('name', descending: false).limit(15).get();
    List<Singer> singers =
        singersSnapshot.docs.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Singer>> getSingersHaveMelodies() async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('melodies', isGreaterThan: 0)
        .orderBy('melodies', descending: true)
        .orderBy('name', descending: false)
        .limit(15)
        .get();
    List<Singer> singers =
        singersSnapshot.docs.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Singer>> getNextSingers(
      String lastVisiblePostSnapShot) async {
    QuerySnapshot singersSnapshot = await singersRef
        .orderBy('name', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Singer> singers =
        singersSnapshot.docs.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Melody>> getSongsBySingerName(String singerName) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .where('singer', isEqualTo: singerName)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> songs =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static Future<List<Melody>> getNextSongsBySingerName(
      String singerName, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .where('singer', isEqualTo: singerName)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> songs =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static Future<List<Melody>> getMelodiesBySingerName(String singerName) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .where('singer', isEqualTo: singerName)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> melodies =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getNextMelodiesBySingerName(
      String singerName, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .where('singer', isEqualTo: singerName)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .orderBy('timestamp', descending: true)
        .get();
    List<Melody> melodies =
        melodiesSnapshot.docs.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<Map> getPostMeta({String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    var postMeta = Map();
    DocumentSnapshot postDocSnapshot =
        await collectionReference.doc(recordId ?? newsId).get();
    if (postDocSnapshot.exists) {
      postMeta['likes'] = postDocSnapshot.data()['likes'];
      postMeta['comments'] = postDocSnapshot.data()['comments'];
    }
    return postMeta;
  }

  static addComment(String commentText,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .add({
      'commenter': Constants.currentUserID,
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp()
    });
    await collectionReference
        .doc(recordId ?? newsId)
        .update({'comments': FieldValue.increment(1)});
  }

  static Future<Map> getReplyMeta(String commentId, String replyId,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    var replyMeta = Map();
    DocumentSnapshot replyDocSnapshot = await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .get();

    if (replyDocSnapshot.exists) {
      replyMeta['likes'] = replyDocSnapshot.data()['likes'];
    }
    return replyMeta;
  }

  static Future<List<Comment>> getCommentReplies(String commentId,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    QuerySnapshot commentSnapshot = await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        ?.orderBy('timestamp', descending: true)
        ?.limit(20)
        ?.get();
    List<Comment> comments =
        commentSnapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getNextCommentReplies(
      String commentId, Timestamp lastVisiblePostSnapShot,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    QuerySnapshot commentSnapshot = await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        ?.orderBy('timestamp', descending: true)
        ?.startAfter([lastVisiblePostSnapShot])
        ?.limit(20)
        ?.get();
    List<Comment> comments =
        commentSnapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<User> getUserWithUsername(String username) async {
    QuerySnapshot userDocSnapshot =
        await usersRef.where('username', isEqualTo: username).get();
    User user =
        userDocSnapshot.docs.map((doc) => User.fromDoc(doc)).toList()[0];

    return user;
  }

  static Future<Map> getCommentMeta(String commentId,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    var commentMeta = Map();
    DocumentSnapshot commentDocSnapshot = await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (commentDocSnapshot.exists) {
      commentMeta['likes'] = commentDocSnapshot.data()['likes'];
      commentMeta['dislikes'] = commentDocSnapshot.data()['dislikes'];
      commentMeta['replies'] = commentDocSnapshot.data()['replies'];
    }
    return commentMeta;
  }

  static Future<Record> getRecordWithId(String recordId) async {
    DocumentSnapshot recordDocSnapshot = await recordsRef?.doc(recordId)?.get();
    if (recordDocSnapshot.exists) {
      return Record.fromDoc(recordDocSnapshot);
    }
    return Record();
  }

  static Future<News> getNewsWithId(String newsId) async {
    DocumentSnapshot newsDocSnapshot = await newsRef?.doc(newsId)?.get();
    if (newsDocSnapshot.exists) {
      return News.fromDoc(newsDocSnapshot);
    }
    return News();
  }

  static deleteComment(String commentId,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    DocumentReference commentRef = collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId);

    (await commentRef.collection('replies').get()).docs.forEach((reply) async {
      (await commentRef
              .collection('replies')
              .doc(reply.id)
              .collection('likes')
              .get())
          .docs
          .forEach((replyLike) {
        commentRef
            .collection('replies')
            .doc(reply.id)
            .collection('likes')
            .doc(replyLike.id)
            .delete();
      });

      (await commentRef
              .collection('replies')
              .doc(reply.id)
              .collection('dislikes')
              .get())
          .docs
          .forEach((replyDislike) {
        commentRef
            .collection('replies')
            .doc(reply.id)
            .collection('dislikes')
            .doc(replyDislike.id)
            .delete();
      });

      commentRef.collection('replies').doc(reply.id).delete();
    });

    (await commentRef.collection('likes').get())
        .docs
        .forEach((commentLike) async {
      await commentRef.collection('likes').doc(commentLike.id).delete();
    });

    (await commentRef.collection('dislikes').get())
        .docs
        .forEach((commentDislike) async {
      await commentRef.collection('dislikes').doc(commentDislike.id).delete();
    });

    await commentRef.delete();

    await recordsRef
        .doc(recordId ?? newsId)
        .update({'comments': FieldValue.increment(-1)});
  }

  static deleteReply(String commentId, String parentCommentId,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    DocumentReference replyRef = collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(parentCommentId)
        .collection('replies')
        .doc(commentId);

    (await replyRef.collection('likes').get()).docs.forEach((replyLike) {
      replyRef.collection('likes').doc(replyLike.id).delete();
    });

    (await replyRef.collection('dislikes').get()).docs.forEach((replyDislike) {
      replyRef.collection('dislikes').doc(replyDislike.id).delete();
    });

    replyRef.delete();

    await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(parentCommentId)
        .update({'replies': FieldValue.increment(-1)});
  }

  static Future<List<Comment>> getComments(
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    QuerySnapshot commentSnapshot = await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        ?.orderBy('timestamp', descending: true)
        ?.limit(20)
        ?.get();
    List<Comment> comments =
        commentSnapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getAllComments(
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    QuerySnapshot commentSnapshot = await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        ?.orderBy('timestamp', descending: true)
        ?.get();
    List<Comment> comments =
        commentSnapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static void addReply(String commentId, String replyText,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'commenter': Constants.currentUserID,
      'text': replyText,
      'timestamp': FieldValue.serverTimestamp()
    });
    await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .update({'replies': FieldValue.increment(1)});
  }

  static Future editComment(String commentId, String commentText,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .update(
            {'text': commentText, 'timestamp': FieldValue.serverTimestamp()});
  }

  static Future editReply(String commentId, String replyId, String replyText,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    await collectionReference
        .doc(recordId ?? newsId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .update({'text': replyText, 'timestamp': FieldValue.serverTimestamp()});
  }

  static Future<List<Category>> getCategories() async {
    QuerySnapshot snapshot = await categoriesRef.get();
    List<Category> categories =
        snapshot.docs.map((doc) => Category.fromDoc(doc)).toList();
    return categories;
  }

  static Future<List<Singer>> getSingersByCategory(String category) async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('category', isEqualTo: category)
        .where('songs', isGreaterThan: 0)
        .orderBy('songs', descending: true)
        .orderBy('name', descending: false)
        .limit(15)
        .get();
    List<Singer> singers =
        singersSnapshot.docs.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Singer>> getNextSingersByCategory(
      String category, String lastVisiblePostSnapShot) async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('category', isEqualTo: category)
        .where('songs', isGreaterThan: 0)
        .orderBy('songs', descending: true)
        .orderBy('name', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Singer> singers =
        singersSnapshot.docs.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static getNews() async {
    QuerySnapshot snapshot =
        await newsRef.orderBy('timestamp', descending: true).get();
    List<News> news = snapshot.docs.map((doc) => News.fromDoc(doc)).toList();
    return news;
  }

  static Future<List<notification.Notification>> getNotifications() async {
    QuerySnapshot notificationSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<notification.Notification> notifications = notificationSnapshot.docs
        .map((doc) => notification.Notification.fromDoc(doc))
        .toList();
    return notifications;
  }

  static Future<List<notification.Notification>> getNextNotifications(
      Timestamp lastVisibleNotificationSnapShot) async {
    QuerySnapshot notificationSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisibleNotificationSnapShot])
        .limit(20)
        .get();
    List<notification.Notification> notifications = notificationSnapshot.docs
        .map((doc) => notification.Notification.fromDoc(doc))
        .toList();
    return notifications;
  }

  static deletePost({String recordId, String newsId}) async {
    if (newsId != null) {
      News news = await getNewsWithId(newsId);
      String fileName =
          await AppUtil.getStorageFileNameFromUrl(news.contentUrl);
      await storageRef.child('/news/$fileName').delete();
    }
    if (recordId != null) {
      Record record = await getRecordWithId(recordId);
      if (record.url != null) {
        String fileName = await AppUtil.getStorageFileNameFromUrl(record.url);
        await storageRef
            .child('/records/${record.melodyId}/$fileName')
            .delete();
      }

      if (record.thumbnailUrl != null) {
        String thumbnail =
            await AppUtil.getStorageFileNameFromUrl(record.thumbnailUrl);
        await storageRef
            .child('/records_thumbnails/${record.melodyId}/$thumbnail')
            .delete();
      }
    }
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    CollectionReference commentsRef =
        collectionReference.doc(recordId ?? newsId).collection('comments');

    CollectionReference likesRef =
        collectionReference.doc(recordId ?? newsId).collection('likes');

    CollectionReference dislikesRef =
        collectionReference.doc(recordId ?? newsId).collection('dislikes');

    (await commentsRef.get()).docs.forEach((comment) async {
      (await commentsRef.doc(comment.id).collection('replies').get())
          .docs
          .forEach((reply) async {
        (await commentsRef
                .doc(comment.id)
                .collection('replies')
                .doc(reply.id)
                .collection('likes')
                .get())
            .docs
            .forEach((replyLike) {
          commentsRef
              .doc(comment.id)
              .collection('replies')
              .doc(reply.id)
              .collection('likes')
              .doc(replyLike.id)
              .delete();
        });

        (await commentsRef
                .doc(comment.id)
                .collection('replies')
                .doc(reply.id)
                .collection('dislikes')
                .get())
            .docs
            .forEach((replyDislike) {
          commentsRef
              .doc(comment.id)
              .collection('replies')
              .doc(reply.id)
              .collection('dislikes')
              .doc(replyDislike.id)
              .delete();
        });

        commentsRef
            .doc(comment.id)
            .collection('replies')
            .doc(reply.id)
            .delete();
      });

      (await commentsRef.doc(comment.id).collection('likes').get())
          .docs
          .forEach((commentLike) async {
        await commentsRef
            .doc(comment.id)
            .collection('likes')
            .doc(commentLike.id)
            .delete();
      });

      (await commentsRef.doc(comment.id).collection('dislikes').get())
          .docs
          .forEach((commentDislike) async {
        await commentsRef
            .doc(comment.id)
            .collection('dislikes')
            .doc(commentDislike.id)
            .delete();
      });

      await commentsRef.doc(comment.id).delete();
    });

    (await likesRef.get()).docs.forEach((like) async {
      await likesRef.doc(like.id).delete();
    });

    (await dislikesRef.get()).docs.forEach((dislike) async {
      await dislikesRef.doc(dislike.id).delete();
    });

    await collectionReference.doc(recordId ?? newsId).delete();
  }

  static Future<List<User>> getUsers() async {
    QuerySnapshot usersSnapshot =
        await usersRef.orderBy('name', descending: true).get();
    List<User> users =
        usersSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();
    return users;
  }

  static deleteMelody(Melody melody) async {
    if (melody.imageUrl != null) {
      String fileName =
          await AppUtil.getStorageFileNameFromUrl(melody.imageUrl);
      await storageRef.child('/melodies_images/$fileName').delete();
    }
    if (melody.audioUrl != null) {
      String fileName =
          await AppUtil.getStorageFileNameFromUrl(melody.audioUrl);
      if (melody.isSong) {
        await storageRef.child('/songs/$fileName').delete();
      } else {
        await storageRef.child('/melodies/$fileName').delete();
      }
    }
    if (melody.levelUrls != null) {
      for (String url in melody.levelUrls.values) {
        String fileName = await AppUtil.getStorageFileNameFromUrl(url);

        await storageRef.child('/melodies/$fileName').delete();
      }
    }
    await melodiesRef.doc(melody.id).delete();
    List<User> users = await getUsers();
    for (User user in users) {
      await usersRef
          .doc(user.id)
          .collection('favourites')
          .doc(melody.id)
          .delete();
      await usersRef
          .doc(user.id)
          .collection('downloads')
          .doc(melody.id)
          .delete();
    }
  }

  static Future<Singer> getSingerWithName(String name) async {
    QuerySnapshot singerSnapshot =
        await singersRef.where('name', isEqualTo: name).get();
    List<Singer> singers =
        singerSnapshot.docs.map((doc) => Singer.fromDoc(doc)).toList();
    return singers[0];
  }

  static Future<List<SlideImage>> getSlideImages(String page) async {
    QuerySnapshot slideImagesSnapshot =
        await slideImagesRef.where('page', isEqualTo: page).get();
    List<SlideImage> slideImages =
        slideImagesSnapshot.docs.map((doc) => SlideImage.fromDoc(doc)).toList();
    return slideImages;
  }

  static deleteSlideImage(SlideImage slideImage) async {
    String fileName = await AppUtil.getStorageFileNameFromUrl(slideImage.url);
    await storageRef.child('/slide_images/$fileName').delete();
    await slideImagesRef.doc(slideImage.id).delete();
  }
}
