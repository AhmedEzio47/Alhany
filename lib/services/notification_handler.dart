import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/main.dart';
import 'package:Alhany/models/news_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'database_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  MyApp.restartApp(NotificationHandler.context);
  print(message.data['type']);
  NotificationHandler.lastNotification = message.data;
}

class NotificationHandler {
  // Create a [AndroidNotificationChannel] for heads up notifications
  static Map<String, dynamic> lastNotification;
  static BuildContext context;
  static AndroidNotificationChannel _channel;

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  static FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  static receiveNotification(
      BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) async {
    NotificationHandler.context = context;
    StreamSubscription iosSubscription;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (!kIsWeb) {
      _channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        'This channel is used for important notifications.', // description
        importance: Importance.high,
      );

      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      /// Create an Android Notification Channel.
      ///
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      /// Update the iOS foreground notification presentation options to allow
      /// heads up notifications.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        navigateToScreen(
            context, message.data['type'], message.data['object_id']);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        _flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                _channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: 'launch_background',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigateToScreen(
          context, message.data['type'], message.data['object_id']);
    });
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
    await usersRef.doc(receiverId).collection('notifications').add({
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

  void configLocalNotification() async {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('ic_launcher');

    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (data) {
      print('data: $data');
    });
  }

  void showNotification(Map<String, dynamic> message) async {
    await configLocalNotification();

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        Platform.isAndroid ? 'com.devyat.alhani' : 'com.devyat.alhani',
        'Alhany',
        'your channel description',
        enableVibration: true,
        importance: Importance.max,
        priority: Priority.high,
        autoCancel: true);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
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
