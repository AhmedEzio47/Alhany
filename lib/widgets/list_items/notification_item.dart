import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/notification_model.dart' as notification_model;
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:flutter/material.dart';

class NotificationItem extends StatefulWidget {
  final notification_model.Notification? notification;
  final String? image;
  final String? senderName;
  final int? counter;

  NotificationItem(
      {Key? key,
      required this.notification,
      this.image,
      this.senderName,
      this.counter})
      : super(key: key);

  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  NotificationHandler notificationHandler = NotificationHandler();

  @override
  Widget build(BuildContext context) {
    print(widget.notification);
    if (widget.notification != null) return _buildItem(widget.notification!);
    return SizedBox.shrink();
  }

  _buildItem(notification_model.Notification notification) {
    return Container(
      color: notification.seen == true
          ? MyColors.lightPrimaryColor.withOpacity(.5)
          : Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(7),
        child: ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: CachedImage(
            imageUrl: widget.image,
            imageShape: BoxShape.circle,
            width: 50.0,
            height: 50.0,
            defaultAssetImage: Strings.default_profile_image,
          ),
          title: Text(
            "${widget.notification?.title}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "${widget.notification?.body}",
            style: TextStyle(
              color: Colors.grey.shade300,
            ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(height: 10),
              Text(
                "${AppUtil.formatTimestamp(widget.notification?.timestamp)}",
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontWeight: FontWeight.w300,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 5),
              widget.counter == 0
                  ? SizedBox()
                  : Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: MyColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 11,
                        minHeight: 11,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 1, left: 5, right: 5),
                        child: Text(
                          "${widget.counter}",
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ],
          ),
          onTap: () {
            if (widget.notification != null && widget.notification!.id != null)
              NotificationHandler.makeNotificationSeen(
                  widget.notification!.id!);
            if (widget.notification != null &&
                widget.notification!.type != null &&
                widget.notification!.objectId != null)
              NotificationHandler.navigateToScreen(context,
                  widget.notification!.type!, widget.notification!.objectId!);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
