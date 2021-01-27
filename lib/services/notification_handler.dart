import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'database_service.dart';

class NotificationHandler {
  static receiveNotification(
      BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
    StreamSubscription iosSubscription;
    FirebaseMessaging _fcm = FirebaseMessaging();

    if (Platform.isIOS) {
      iosSubscription = _fcm.onIosSettingsRegistered.listen((data) {
        // save the token  OR subscribe to a topic here
      });

      _fcm.requestNotificationPermissions(IosNotificationSettings());
    }

    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        makeNotificationSeen(message['data']['id']);

        AppUtil.showToast(
          message['notification']['title'],
        );

        //showNotification(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        makeNotificationSeen(message['data']['id']);

        navigateToScreen(
            context, message['data']['type'], message['data']['object_id']);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        makeNotificationSeen(message['data']['id']);
        navigateToScreen(
            context, message['data']['type'], message['data']['object_id']);
      },
    );
  }

  static makeNotificationSeen(String notificationId) {
    usersRef
        .doc(Constants.currentUserID)
        .collection('notifications')
        .doc(notificationId)
        .update({
      'seen': true,
    });
  }

  static navigateToScreen(
      BuildContext context, String type, String objectId) async {
    switch (type) {
      case 'message':
        Navigator.of(context)
            .pushNamed('/conversation', arguments: {'other_uid': objectId});
        break;

      case 'follow':
        Navigator.of(context)
            .pushNamed('/profile-page', arguments: {'user_id': objectId});
        break;
      case 'news_like':
        News news = await DatabaseService.getNewsWithId(objectId);
        Navigator.of(context).pushNamed('/news-page',
            arguments: {'news': news, 'is_video_visible': true});
        break;
      case 'news_comment':
        News news = await DatabaseService.getNewsWithId(objectId);
        Navigator.of(context).pushNamed('/news-page',
            arguments: {'news': news, 'is_video_visible': true});
        break;
      case 'record_like':
        Record record = await DatabaseService.getRecordWithId(objectId);
        Navigator.of(context).pushNamed('/record-page',
            arguments: {'record': record, 'is_video_visible': true});
        break;
      case 'record_comment':
        Record record = await DatabaseService.getRecordWithId(objectId);
        Navigator.of(context).pushNamed('/record-page',
            arguments: {'record': record, 'is_video_visible': true});
        break;
    }
  }

  static sendNotification(String receiverId, String title, String body,
      String objectId, String type) async {
    if (receiverId == Constants.currentUserID) return;
    usersRef.doc(receiverId).collection('notifications').add({
      'title': title,
      'body': body,
      'seen': false,
      'timestamp': FieldValue.serverTimestamp(),
      'sender': Constants.currentUserID,
      'object_id': objectId,
      'type': type
    });

    //To increment notificationsNumber
    //User user = await DatabaseService.getUserWithId(receiverId);
    await usersRef
        .doc(receiverId)
        .update({'notificationsNumber': FieldValue.increment(1)});
  }

  static removeNotification(
      String receiverId, String objectId, String type) async {
    await DatabaseService.removeNotification(receiverId, objectId, type);

    print('noti removed');
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(Map<String, dynamic> message) async {
    configLocalNotification();

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        Platform.isAndroid ? 'com.devyat.alhani' : 'com.devyat.alhani',
        'Alhany',
        'your channel description',
        enableVibration: true,
        importance: Importance.Max,
        priority: Priority.High,
        autoCancel: true);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        message['notification']['title'].toString(),
        message['notification']['body'].toString(),
        platformChannelSpecifics,
        payload: json.encode(message));
  }

  clearNotificationsNumber() async {
    await usersRef
        .doc(Constants.currentUserID)
        .update({'notificationsNumber': 0});
  }
}
