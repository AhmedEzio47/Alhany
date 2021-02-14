import 'dart:async';
import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/message_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/audio_recorder.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/permissions_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/chat_bubble.dart';
import 'package:Alhany/widgets/image_edit_bottom_sheet.dart';
import 'package:Alhany/widgets/image_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class Conversation extends StatefulWidget {
  final String otherUid;
  final _ConversationState state = _ConversationState();
  Conversation({this.otherUid});

  updateRecordTime(String recordTime) {
    print('recordTime: $recordTime');
    state.updateRecordTime(recordTime);
  }

  @override
  _ConversationState createState() => state;
}

class _ConversationState extends State<Conversation>
    with WidgetsBindingObserver {
  bool isMicrophoneGranted = false;

  User otherUser = User();
  Timestamp firstVisibleGameSnapShot;
  String messageText;
  bool _typing = false;
  FocusScopeNode _focusNode = FocusScopeNode();
  AudioRecorder recorder;
  var _url;
  List<Message> _messages;

  TextEditingController messageController = TextEditingController();

  var seen = false;
  final formatter = new NumberFormat("##");

  StreamSubscription<QuerySnapshot> messagesSubscription;

  ScrollController _scrollController = ScrollController();

  String recordTime = 'recording...';

  var _currentStatus;

  _ConversationState();

  initRecorder() async {
    recorder = AudioRecorder();
    await recorder.init();
  }

  void loadUserData(String uid) async {
    User user;
    user = await DatabaseService.getUserWithId(uid);
    setState(() {
      otherUser = user;
    });
  }

  void getMessages() async {
    var messages = await DatabaseService.getMessages(widget.otherUid);
    setState(() {
      this._messages = messages;
      this.firstVisibleGameSnapShot = messages.last.timestamp;
    });
  }

  void getPrevMessages() async {
    var messages;
    messages = await DatabaseService.getPrevMessages(
        firstVisibleGameSnapShot, widget.otherUid);

    if (messages.length > 0) {
      setState(() {
        messages.forEach((element) => this._messages.add(element));
        this.firstVisibleGameSnapShot = messages.last.timestamp;
      });
    }
  }

  void listenToMessagesChanges() async {
    messagesSubscription = chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(widget.otherUid)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      querySnapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          print('type is her');
          if (_messages != null) {
            if (this.mounted) {
              setState(() {
                _messages.insert(0, Message.fromDoc(change.doc));
              });
            }
          }
        }

        if (Message.fromDoc(change.doc).sender == widget.otherUid) {
          makeMessagesSeen();
        }
      });
    });
  }

  void listenIfMessagesSeen() {
    chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(widget.otherUid)
        .collection('messages')
        .snapshots()
        .listen((querySnapshot) {
      querySnapshot.docChanges.forEach((change) {
        if (change.doc.id == 'seen') {
          if (this.mounted) {
            setState(() {
              seen = change.doc.data()['isSeen'];
              print('seen');
            });
          }
        }
      });
    });
  }

  void otherUserListener() {
    usersRef.snapshots().listen((querySnapshot) {
      querySnapshot.docChanges.forEach((change) {
        if (change.doc.id == widget.otherUid) {
          if (mounted) {
            setState(() {
              otherUser = User.fromDoc(change.doc);
            });
          }
        }
      });
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
      if (diff.inMinutes == 1) {
        time = 'A minute ago';
      } else {
        time = diff.inMinutes.toString() + ' minutes ago';
      }
    } else if (diff.inHours > 0 && diff.inHours < 24) {
      if (diff.inHours == 1) {
        time = 'An hour ago';
      } else {
        time = diff.inHours.toString() + ' hours ago';
      }
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = 'Yesterday';
      } else {
        time = diff.inDays.toString() + ' DAYS AGO';
      }
    } else {
      if (diff.inDays == 7) {
        time = 'A WEEK AGO';
      } else {
        time = timestamp.toDate().toString();
      }
    }

    return time;
  }

  void updateOnlineUserState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await usersRef
          .doc(Constants.currentUserID)
          .update({'online': FieldValue.serverTimestamp()});
    } else if (state == AppLifecycleState.resumed) {
      await usersRef.doc(Constants.currentUserID).update({'online': 'online'});
    }
  }

  makeMessagesSeen() async {
    await chatsRef
        .doc(widget.otherUid)
        .collection('conversations')
        .doc(Constants.currentUserID)
        .set({'isSeen': true});
  }

  makeMessagesUnseen() async {
    await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(widget.otherUid)
        .set({'isSeen': false});

    await chatsRef
        .doc(widget.otherUid)
        .collection('conversations')
        .doc(Constants.currentUserID)
        .set({'isSeen': false});
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _typing = true;
    } else {
      _focusNode.unfocus();
      _typing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    updateOnlineUserState(state);
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
      messagesSubscription.resume();
    } else if (state == AppLifecycleState.paused) {
      // app is inactive
      messagesSubscription.pause();
    } else if (state == AppLifecycleState.detached) {
      // app suspended (not used in iOS)
    }
  }

  @override
  void initState() {
    super.initState();
    //_loadAudioByteData();
    WidgetsBinding.instance.addObserver(this);
    getMessages();
    listenToMessagesChanges();
    otherUserListener();
    listenIfMessagesSeen();
    loadUserData(widget.otherUid);
    //initRecorder();

    _focusNode.addListener(_onFocusChange);

    ///Set up listener here
    _scrollController
      ..addListener(() {
        if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent &&
            !_scrollController.position.outOfRange) {
          print('reached the bottom');
          getPrevMessages();
        } else if (_scrollController.offset <=
                _scrollController.position.minScrollExtent &&
            !_scrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messagesSubscription.cancel();
    _scrollController.dispose();
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackBtnPressed,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _focusNode.unfocus();
            _typing = false;
          });

          // if (!_focusNode.hasPrimaryFocus) {
          //   _focusNode.unfocus();
          // }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: Icon(
                  Icons.keyboard_backspace,
                ),
                onPressed: () async {
                  _onBackBtnPressed();
                }),
            titleSpacing: 0,
            title: InkWell(
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 0.0, right: 10.0),
                    child: CachedImage(
                      imageUrl: otherUser.profileImageUrl,
                      imageShape: BoxShape.circle,
                      width: 50.0,
                      height: 50.0,
                      defaultAssetImage: Strings.default_profile_image,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 15.0),
                        Text(
                          otherUser.name ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          otherUser != null
                              ? otherUser.online == 'online'
                                  ? 'online'
                                  : 'offline'
                              : '',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/user-profile',
                    arguments: {'userId': widget.otherUid});
              },
            ),
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                _messages != null
                    ? Flexible(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _messages.length,
                          reverse: true,
                          itemBuilder: (BuildContext context, int index) {
                            Message msg = _messages[index];
                            return ChatBubble(
                              message: msg.message,
                              username: otherUser.name,
                              time: msg.timestamp != null
                                  ? formatTimestamp(msg.timestamp)
                                  : 'now',
                              type: msg.type,
                              replyText: null,
                              isMe: msg.sender == Constants.currentUserID,
                              isGroup: false,
                              isReply: false,
                              replyName: null,
                            );
                          },
                        ),
                      )
                    : Container(),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                      child: Text(
                        seen ? 'seen' : '',
                        style: TextStyle(color: Colors.white),
                      ),
                    )),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
//                height: 140,
                    decoration: BoxDecoration(
                      color: MyColors.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[500],
                          offset: Offset(0.0, 1.5),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxHeight: 190,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                ImageEditBottomSheet bottomSheet =
                                    ImageEditBottomSheet();
                                await bottomSheet.openBottomSheet(context);

                                File image;
                                if (bottomSheet.source == ImageSource.gallery) {
                                  image = await AppUtil.pickImageFromGallery();
                                } else if (bottomSheet.source ==
                                    ImageSource.camera) {
                                  image = await AppUtil.takePhoto();
                                } else {
                                  AppUtil.showToast(language(
                                      en: 'Nothing chosen',
                                      ar: 'لم يتم اختيار صورة'));
                                  return;
                                }

                                if (image != null) {
                                  showDialog(
                                      barrierDismissible: true,
                                      builder: (_) => Container(
                                            width: 300,
                                            height: 300,
                                            child: ImageOverlay(
                                                imageFile: image,
                                                btnIcons: [
                                                  Icons.send
                                                ],
                                                btnFunctions: [
                                                  () async {
                                                    String url = await AppUtil()
                                                        .uploadFile(
                                                            image,
                                                            context,
                                                            'image_messages/${Constants.currentUserID}/${widget.otherUid}/${randomAlphaNumeric(20)}${path.extension(image.path)}');

                                                    messageController.clear();
                                                    await DatabaseService
                                                        .sendMessage(
                                                            widget.otherUid,
                                                            'image',
                                                            url);
                                                    makeMessagesUnseen();

                                                    Navigator.of(context).pop();
                                                  },
                                                ]),
                                          ),
                                      context: context);
                                }
                              },
                            ),
                            contentPadding: EdgeInsets.all(0),
                            title: _currentStatus != RecordingStatus.Recording
                                ? TextField(
                                    cursorColor: Colors.white,
                                    focusNode: _focusNode,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    controller: messageController,
                                    onChanged: (value) {
                                      messageText = value;
                                    },
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(10.0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        borderSide: BorderSide(
                                          color: MyColors.primaryColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: MyColors.primaryColor,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      hintText: "Write your message...",
                                      hintStyle: TextStyle(
                                        fontSize: 15.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                    maxLines: null,
                                  )
                                : Text(recordTime),
                            trailing: _typing
                                ? IconButton(
                                    icon: Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      messageController.clear();
                                      await DatabaseService.sendMessage(
                                          widget.otherUid, 'text', messageText);
                                    },
                                  )
                                : GestureDetector(
                                    onLongPress: () async {
                                      if (await PermissionsService()
                                          .hasMicrophonePermission()) {
                                        setState(() {
                                          isMicrophoneGranted = true;
                                        });
                                      } else {
                                        bool isGranted =
                                            await PermissionsService()
                                                .requestMicrophonePermission(
                                                    context,
                                                    onPermissionDenied: () {
                                          AppUtil.showAlertDialog(
                                              context: context,
                                              heading: 'info',
                                              message:
                                                  'You must grant this microphone access to be able to use this feature.',
                                              firstBtnText: 'OK',
                                              firstFunc: () {
                                                Navigator.of(context).pop();
                                              });
                                          print('Permission has been denied');
                                        });
                                        setState(() {
                                          isMicrophoneGranted = isGranted;
                                        });
                                        return;
                                      }

                                      if (isMicrophoneGranted) {
                                        setState(() {
                                          _currentStatus =
                                              RecordingStatus.Recording;
                                        });
                                        await initRecorder();
                                        await recorder.startRecording();
                                      } else {}
                                    },
                                    onLongPressEnd: (longPressDetails) async {
                                      if (isMicrophoneGranted) {
                                        setState(() {
                                          _currentStatus =
                                              RecordingStatus.Stopped;
                                        });
                                        String result =
                                            await recorder.stopRecording();

                                        //Storage path is voice_messages/sender_id/receiver_id/file
                                        _url = await AppUtil().uploadFile(
                                            File(result),
                                            context,
                                            'voice_messages/${Constants.currentUserID}/${widget.otherUid}/${randomAlphaNumeric(20)}${path.extension(result)}');

                                        await DatabaseService.sendMessage(
                                            widget.otherUid, 'audio', _url);
                                      }
                                    },
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.mic,
                                        color: Colors.white,
                                      ),
                                      onPressed: null,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void updateRecordTime(String rt) {
    if (mounted) {
      setState(() {
        recordTime = rt;
      });
    }
  }

  Future<bool> _onBackBtnPressed() async {
    var message = await DatabaseService.getLastMessage(widget.otherUid);
    Navigator.of(context).pop(message);
  }
}
