import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/sizes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/notification_model.dart' as notification_model;
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:Alhany/widgets/list_items/notification_item.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<notification_model.Notification> _notifications = [];
  ScrollController _scrollController = ScrollController();

  Timestamp lastVisibleNotificationSnapShot;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: MyColors.primaryColor,
                image: DecorationImage(
                  colorFilter: new ColorFilter.mode(
                      Colors.black.withOpacity(0.1), BlendMode.dstATop),
                  image: AssetImage(Strings.default_bg),
                  fit: BoxFit.cover,
                ),
              ),
              child: authStatus == AuthStatus.NOT_LOGGED_IN
                  ? Center(
                      child: Text(
                        language(
                            en: 'Please log in to see page content',
                            ar: 'من فضلك قم بتسجيل الدخول لترى محتوى الصفحة'),
                        style: TextStyle(color: MyColors.textLightColor),
                      ),
                    )
                  : _notifications.length > 0
                      ? SingleChildScrollView(
                          controller: _scrollController,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: _notifications.length,
                              itemBuilder: (BuildContext context, int index) {
                                notification_model.Notification notification =
                                    _notifications[index];

                                return FutureBuilder(
                                    future: DatabaseService.getUserWithId(
                                        notification.sender),
                                    builder: (BuildContext context,
                                        AsyncSnapshot snapshot) {
                                      if (!snapshot.hasData) {
                                        return SizedBox.shrink();
                                      }
                                      User sender = snapshot.data;
                                      return Column(
                                        children: <Widget>[
                                          NotificationItem(
                                            key: ValueKey(notification.id),
                                            notification: notification,
                                            image: sender.profileImageUrl,
                                            senderName: sender.username,
                                            counter: 0,
                                          ),
                                          Divider(
                                              height: .5, color: Colors.grey)
                                        ],
                                      );
                                    });
                              },
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                          'No notifications yet',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        )),
            ),
            Positioned.fill(
                child: Align(
              child: RegularAppbar(
                context,
                color: Colors.black,
                height: Sizes.appbar_height,
                margin: 25,
                leading: Padding(
                  padding: const EdgeInsets.only(
                    left: 15.0,
                  ),
                  child: Builder(
                    builder: (context) => InkWell(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: Icon(
                        Icons.menu,
                        color: MyColors.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              alignment: Alignment.topCenter,
            )),
          ],
        ),
        drawer: BuildDrawer(),
      ),
    );
  }

  _setupFeed() async {
    List<notification_model.Notification> notifications =
        await DatabaseService.getNotifications();
    setState(() {
      _notifications = notifications;
      this.lastVisibleNotificationSnapShot = notifications.last.timestamp;
    });
  }

  void nextNotifications() async {
    var notifications = await DatabaseService.getNextNotifications(
        lastVisibleNotificationSnapShot);
    if (notifications.length > 0) {
      setState(() {
        notifications.forEach((element) => _notifications.add(element));
        this.lastVisibleNotificationSnapShot = _notifications.last.timestamp;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController
      ..addListener(() {
        if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent &&
            !_scrollController.position.outOfRange) {
          print('reached the bottom');
          nextNotifications();
        } else if (_scrollController.offset <=
                _scrollController.position.minScrollExtent &&
            !_scrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    _setupFeed();
  }

  Future<bool> _onBackPressed() {
    /// Navigate back to home page
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
