import 'package:Alhany/constants/constants.dart';
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

  static addUserToDatabase(String id, String email, String name, String username) async {
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

  static searchSingers(String text) async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('search', arrayContains: text)
        .limit(20)
        .orderBy('name', descending: false)
        .getDocuments();
    List<Singer> singers = singersSnapshot.documents.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Record>> getRecords() async {
    QuerySnapshot recordsSnapshot = await recordsRef.limit(20).orderBy('timestamp', descending: true).getDocuments();
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

  static Future<Record> getNextRecord(Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(1)
        .getDocuments();
    List<Record> records = recordsSnapshot.documents.map((doc) => Record.fromDoc(doc)).toList();
    return records[0];
  }

  static Future<Record> getPrevRecord(Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot recordsSnapshot = await recordsRef
        .orderBy('timestamp', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(1)
        .getDocuments();
    List<Record> records = recordsSnapshot.documents.map((doc) => Record.fromDoc(doc)).toList();
    return records[0];
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

  static submitRecord(String melodyId, String recordId, String url, int duration) async {
    await recordsRef.document(recordId).setData({
      'audio_url': url,
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

    await chatsRef.document(otherUserId).collection('conversations').document(Constants.currentUserID).setData({
      'last_message_timestamp': FieldValue.serverTimestamp(),
    });

    await chatsRef.document(Constants.currentUserID).collection('conversations').document(otherUserId).setData({
      'last_message_timestamp': FieldValue.serverTimestamp(),
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

  static incrementRecordViews(String recordId) async {
    await recordsRef.document(recordId).updateData({'views': FieldValue.increment(1)});
  }

  static incrementNewsViews(String newsId) async {
    await newsRef.document(newsId).updateData({'views': FieldValue.increment(1)});
  }

  static Future<List<Singer>> getSingers() async {
    QuerySnapshot singersSnapshot = await singersRef.orderBy('name', descending: false).limit(15).getDocuments();
    List<Singer> singers = singersSnapshot.documents.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Singer>> getSingersHaveMelodies() async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('melodies', isGreaterThan: 0)
        .orderBy('melodies', descending: true)
        .orderBy('name', descending: false)
        .limit(15)
        .getDocuments();
    List<Singer> singers = singersSnapshot.documents.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Singer>> getNextSingers(String lastVisiblePostSnapShot) async {
    QuerySnapshot singersSnapshot = await singersRef
        .orderBy('name', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
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

  static Future<List<Melody>> getNextSongsBySingerName(String singerName, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: true)
        .where('singer', isEqualTo: singerName)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> songs = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return songs;
  }

  static Future<List<Melody>> getMelodiesBySingerName(String singerName) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .where('singer', isEqualTo: singerName)
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> melodies = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
    return melodies;
  }

  static Future<List<Melody>> getNextMelodiesBySingerName(String singerName, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot melodiesSnapshot = await melodiesRef
        .where('is_song', isEqualTo: false)
        .where('singer', isEqualTo: singerName)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Melody> melodies = melodiesSnapshot.documents.map((doc) => Melody.fromDoc(doc)).toList();
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
    DocumentSnapshot postDocSnapshot = await collectionReference.document(recordId ?? newsId).get();
    if (postDocSnapshot.exists) {
      postMeta['likes'] = postDocSnapshot.data['likes'];
      postMeta['comments'] = postDocSnapshot.data['comments'];
    }
    return postMeta;
  }

  static addComment(String commentText, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .add({'commenter': Constants.currentUserID, 'text': commentText, 'timestamp': FieldValue.serverTimestamp()});
    await collectionReference.document(recordId ?? newsId).updateData({'comments': FieldValue.increment(1)});
  }

  static Future<Map> getReplyMeta(String commentId, String replyId, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    var replyMeta = Map();
    DocumentSnapshot replyDocSnapshot = await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        .document(replyId)
        .get();

    if (replyDocSnapshot.exists) {
      replyMeta['likes'] = replyDocSnapshot.data['likes'];
    }
    return replyMeta;
  }

  static Future<List<Comment>> getCommentReplies(String commentId, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    QuerySnapshot commentSnapshot = await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        ?.orderBy('timestamp', descending: true)
        ?.limit(20)
        ?.getDocuments();
    List<Comment> comments = commentSnapshot.documents.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getNextCommentReplies(String commentId, Timestamp lastVisiblePostSnapShot,
      {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    QuerySnapshot commentSnapshot = await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        ?.orderBy('timestamp', descending: true)
        ?.startAfter([lastVisiblePostSnapShot])
        ?.limit(20)
        ?.getDocuments();
    List<Comment> comments = commentSnapshot.documents.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<User> getUserWithUsername(String username) async {
    QuerySnapshot userDocSnapshot = await usersRef.where('username', isEqualTo: username).getDocuments();
    User user = userDocSnapshot.documents.map((doc) => User.fromDoc(doc)).toList()[0];

    return user;
  }

  static Future<Map> getCommentMeta(String commentId, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    var commentMeta = Map();
    DocumentSnapshot commentDocSnapshot =
        await collectionReference.document(recordId ?? newsId).collection('comments').document(commentId).get();

    if (commentDocSnapshot.exists) {
      commentMeta['likes'] = commentDocSnapshot.data['likes'];
      commentMeta['dislikes'] = commentDocSnapshot.data['dislikes'];
      commentMeta['replies'] = commentDocSnapshot.data['replies'];
    }
    return commentMeta;
  }

  static Future<Record> getRecordWithId(String recordId) async {
    DocumentSnapshot recordDocSnapshot = await recordsRef?.document(recordId)?.get();
    if (recordDocSnapshot.exists) {
      return Record.fromDoc(recordDocSnapshot);
    }
    return Record();
  }

  static Future<News> getNewsWithId(String newsId) async {
    DocumentSnapshot newsDocSnapshot = await newsRef?.document(newsId)?.get();
    if (newsDocSnapshot.exists) {
      return News.fromDoc(newsDocSnapshot);
    }
    return News();
  }

  static deleteComment(String commentId, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    DocumentReference commentRef =
        collectionReference.document(recordId ?? newsId).collection('comments').document(commentId);

    (await commentRef.collection('replies').getDocuments()).documents.forEach((reply) async {
      (await commentRef.collection('replies').document(reply.documentID).collection('likes').getDocuments())
          .documents
          .forEach((replyLike) {
        commentRef
            .collection('replies')
            .document(reply.documentID)
            .collection('likes')
            .document(replyLike.documentID)
            .delete();
      });

      (await commentRef.collection('replies').document(reply.documentID).collection('dislikes').getDocuments())
          .documents
          .forEach((replyDislike) {
        commentRef
            .collection('replies')
            .document(reply.documentID)
            .collection('dislikes')
            .document(replyDislike.documentID)
            .delete();
      });

      commentRef.collection('replies').document(reply.documentID).delete();
    });

    (await commentRef.collection('likes').getDocuments()).documents.forEach((commentLike) async {
      await commentRef.collection('likes').document(commentLike.documentID).delete();
    });

    (await commentRef.collection('dislikes').getDocuments()).documents.forEach((commentDislike) async {
      await commentRef.collection('dislikes').document(commentDislike.documentID).delete();
    });

    await commentRef.delete();

    await recordsRef.document(recordId ?? newsId).updateData({'comments': FieldValue.increment(-1)});
  }

  static deleteReply(String commentId, String parentCommentId, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    DocumentReference replyRef = collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(parentCommentId)
        .collection('replies')
        .document(commentId);

    (await replyRef.collection('likes').getDocuments()).documents.forEach((replyLike) {
      replyRef.collection('likes').document(replyLike.documentID).delete();
    });

    (await replyRef.collection('dislikes').getDocuments()).documents.forEach((replyDislike) {
      replyRef.collection('dislikes').document(replyDislike.documentID).delete();
    });

    replyRef.delete();

    await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(parentCommentId)
        .updateData({'replies': FieldValue.increment(-1)});
  }

  static Future<List<Comment>> getComments({String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    QuerySnapshot commentSnapshot = await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        ?.orderBy('timestamp', descending: true)
        ?.limit(20)
        ?.getDocuments();
    List<Comment> comments = commentSnapshot.documents.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getAllComments({String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    QuerySnapshot commentSnapshot = await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        ?.orderBy('timestamp', descending: true)
        ?.getDocuments();
    List<Comment> comments = commentSnapshot.documents.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static void addReply(String commentId, String replyText, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }
    await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        .add({'commenter': Constants.currentUserID, 'text': replyText, 'timestamp': FieldValue.serverTimestamp()});
    await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(commentId)
        .updateData({'replies': FieldValue.increment(1)});
  }

  static Future editComment(String commentId, String commentText, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(commentId)
        .updateData({'text': commentText, 'timestamp': FieldValue.serverTimestamp()});
  }

  static Future editReply(String commentId, String replyId, String replyText, {String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    await collectionReference
        .document(recordId ?? newsId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        .document(replyId)
        .updateData({'text': replyText, 'timestamp': FieldValue.serverTimestamp()});
  }

  static getCategories() async {
    QuerySnapshot snapshot = await categoriesRef.getDocuments();
    List<String> categories = [];
    for (DocumentSnapshot category in snapshot.documents) {
      categories.add(category.data['name']);
    }
    return categories;
  }

  static Future<List<Singer>> getSingersByCategory(String category) async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('category', isEqualTo: category)
        .where('songs', isGreaterThan: 0)
        .orderBy('songs', descending: true)
        .orderBy('name', descending: false)
        .limit(15)
        .getDocuments();
    List<Singer> singers = singersSnapshot.documents.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static Future<List<Singer>> getNextSingersByCategory(String category, String lastVisiblePostSnapShot) async {
    QuerySnapshot singersSnapshot = await singersRef
        .where('category', isEqualTo: category)
        .where('songs', isGreaterThan: 0)
        .orderBy('songs', descending: true)
        .orderBy('name', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Singer> singers = singersSnapshot.documents.map((doc) => Singer.fromDoc(doc)).toList();
    return singers;
  }

  static getNews() async {
    QuerySnapshot snapshot = await newsRef.orderBy('timestamp', descending: true).getDocuments();
    List<News> news = snapshot.documents.map((doc) => News.fromDoc(doc)).toList();
    return news;
  }

  static Future<List<notification.Notification>> getNotifications() async {
    QuerySnapshot notificationSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<notification.Notification> notifications =
        notificationSnapshot.documents.map((doc) => notification.Notification.fromDoc(doc)).toList();
    return notifications;
  }

  static Future<List<notification.Notification>> getNextNotifications(Timestamp lastVisibleNotificationSnapShot) async {
    QuerySnapshot notificationSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisibleNotificationSnapShot])
        .limit(20)
        .getDocuments();
    List<notification.Notification> notifications =
        notificationSnapshot.documents.map((doc) => notification.Notification.fromDoc(doc)).toList();
    return notifications;
  }

  static deletePost({String recordId, String newsId}) async {
    CollectionReference collectionReference;
    if (recordId != null) {
      collectionReference = recordsRef;
    } else if (newsId != null) {
      collectionReference = newsRef;
    }

    CollectionReference commentsRef = collectionReference.document(recordId ?? newsId).collection('comments');

    CollectionReference likesRef = collectionReference.document(recordId ?? newsId).collection('likes');

    CollectionReference dislikesRef = collectionReference.document(recordId ?? newsId).collection('dislikes');

    (await commentsRef.getDocuments()).documents.forEach((comment) async {
      (await commentsRef.document(comment.documentID).collection('replies').getDocuments())
          .documents
          .forEach((reply) async {
        (await commentsRef
                .document(comment.documentID)
                .collection('replies')
                .document(reply.documentID)
                .collection('likes')
                .getDocuments())
            .documents
            .forEach((replyLike) {
          commentsRef
              .document(comment.documentID)
              .collection('replies')
              .document(reply.documentID)
              .collection('likes')
              .document(replyLike.documentID)
              .delete();
        });

        (await commentsRef
                .document(comment.documentID)
                .collection('replies')
                .document(reply.documentID)
                .collection('dislikes')
                .getDocuments())
            .documents
            .forEach((replyDislike) {
          commentsRef
              .document(comment.documentID)
              .collection('replies')
              .document(reply.documentID)
              .collection('dislikes')
              .document(replyDislike.documentID)
              .delete();
        });

        commentsRef.document(comment.documentID).collection('replies').document(reply.documentID).delete();
      });

      (await commentsRef.document(comment.documentID).collection('likes').getDocuments())
          .documents
          .forEach((commentLike) async {
        await commentsRef.document(comment.documentID).collection('likes').document(commentLike.documentID).delete();
      });

      (await commentsRef.document(comment.documentID).collection('dislikes').getDocuments())
          .documents
          .forEach((commentDislike) async {
        await commentsRef
            .document(comment.documentID)
            .collection('dislikes')
            .document(commentDislike.documentID)
            .delete();
      });

      await commentsRef.document(comment.documentID).delete();
    });

    (await likesRef.getDocuments()).documents.forEach((like) async {
      await likesRef.document(like.documentID).delete();
    });

    (await dislikesRef.getDocuments()).documents.forEach((dislike) async {
      await dislikesRef.document(dislike.documentID).delete();
    });

    await collectionReference.document(recordId ?? newsId).delete();
  }

  static Future<List<User>> getUsers() async {
    QuerySnapshot usersSnapshot = await usersRef.orderBy('name', descending: true).getDocuments();
    List<User> users = usersSnapshot.documents.map((doc) => User.fromDoc(doc)).toList();
    return users;
  }

  static deleteMelody(Melody melody) async {
    if (melody.imageUrl != null) {
      String fileName = await AppUtil.getStorageFileNameFromUrl(melody.imageUrl);
      await storageRef.child('/melodies_images/$fileName').delete();
    }
    if (melody.audioUrl != null) {
      String fileName = await AppUtil.getStorageFileNameFromUrl(melody.audioUrl);
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
    await melodiesRef.document(melody.id).delete();
    List<User> users = await getUsers();
    for (User user in users) {
      await usersRef.document(user.id).collection('favourites').document(melody.id).delete();
      await usersRef.document(user.id).collection('downloads').document(melody.id).delete();
    }
  }

  static Future<Singer> getSingerWithName(String name) async {
    QuerySnapshot singerSnapshot = await singersRef.where('name', isEqualTo: name).getDocuments();
    List<Singer> singers = singerSnapshot.documents.map((doc) => Singer.fromDoc(doc)).toList();
    return singers[0];
  }

  static Future<List<SlideImage>> getSlideImages() async {
    QuerySnapshot slideImagesSnapshot = await slideImagesRef.getDocuments();
    List<SlideImage> slideImages = slideImagesSnapshot.documents.map((doc) => SlideImage.fromDoc(doc)).toList();
    return slideImages;
  }

  static deleteSlideImage(SlideImage slideImage) async {
    String fileName = await AppUtil.getStorageFileNameFromUrl(slideImage.url);
    await storageRef.child('/slide_images/$fileName').delete();
    await slideImagesRef.document(slideImage.id).delete();
  }
}
