import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/message_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/drawer.dart';
import 'package:Alhany/widgets/list_items/chat_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Chats extends StatefulWidget {
  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<String> _chattersIds = [];

  bool _searching = false;

  List<ChatItem> _filteredChats = [];
  List<ChatItem> _chats = [];

  TextEditingController _searchController = TextEditingController();

  void getChats() async {
    List<String> chattersIds = await DatabaseService.getChats();

    for (String chatterId in chattersIds) {
      await loadUserData(chatterId);
      await sortChatItems();
    }

    setState(() {
      this._chattersIds = chattersIds;
    });
  }

  Future<ChatItem> loadUserData(String uid) async {
    ChatItem chatItem;
    User user = await DatabaseService.getUserWithId(uid);
    Message message = await DatabaseService.getLastMessage(user.id);
    setState(() {
      chatItem = ChatItem(
        key: ValueKey(uid),
        dp: user.profileImageUrl,
        name: user.name,
        isOnline: user.online == 'online',
        msg: message ?? 'No messages yet',
        counter: 0,
      );
      _chats.add(chatItem);
    });

    return chatItem;
  }

  @override
  void initState() {
    getChats();
    super.initState();
  }

  sortChatItems() {
    int n = _chats.length;
    for (int i = 0; i < n - 1; i++) {
      for (int j = 0; j < n - i - 1; j++) {
        var current = _chats[j].msg.timestamp;
        if (current == null) {
          current = Timestamp.fromDate(DateTime.now());
        }
        var next = _chats[j + 1].msg.timestamp;
        if (next == null) {
          next = Timestamp.fromDate(DateTime.now());
        }
        if (current.seconds <= next.seconds) {
          setState(() {
            ChatItem temp = _chats[j];
            _chats[j] = _chats[j + 1];
            _chats[j + 1] = temp;
          });
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    sortChatItems();
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    updateOnlineUserState(state);
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
      getChats();
      print('resumed');
    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
      //_setupFeed();
      print('inactive');
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
      //_setupFeed();
      print('paused');
    } else if (state == AppLifecycleState.detached) {
      // app suspended (not used in iOS)
    }
  }

  void updateOnlineUserState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      DatabaseService.makeUserOffline();
    } else if (state == AppLifecycleState.resumed) {
      DatabaseService.makeUserOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        drawer: BuildDrawer(),
        body: Stack(
          children: [
            Container(
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
                  : Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: _chats.length > 0
                          ? ListView.separated(
                              padding: EdgeInsets.all(10),
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    height: 0.5,
                                    width:
                                        MediaQuery.of(context).size.width / 1.3,
                                    child: Divider(),
                                  ),
                                );
                              },
                              itemCount: !_searching
                                  ? _chats.length
                                  : _filteredChats.length,
                              itemBuilder: !_searching
                                  ? (BuildContext context, int index) {
                                      ChatItem chat = _chats[index];
                                      return chat;
                                    }
                                  : (BuildContext context, int index) {
                                      ChatItem chat = _filteredChats[index];
                                      return chat;
                                    },
                            )
                          : Center(
                              child: Text(
                              'No chats yet',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: MyColors.textInactiveColor),
                            )),
                    ),
            ),
            Positioned.fill(
                child: Padding(
              padding: const EdgeInsets.only(left: 50, top: 30),
              child: Align(
                alignment: Alignment.topRight,
                child: TextField(
                  cursorColor: Colors.white,
                  controller: _searchController,
                  style: TextStyle(color: MyColors.textLightColor),
                  decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        size: 28.0,
                        color: MyColors.iconLightColor,
                      ),
                      suffixIcon: _searching
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: MyColors.iconLightColor,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              })
                          : null,
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: MyColors.textLightColor,
                      )),
                  onChanged: (text) {
                    _filteredChats = [];
                    if (text.length != 0) {
                      setState(() {
                        _searching = true;
                      });
                    } else {
                      setState(() {
                        _searching = false;
                      });
                    }
                    _chats.forEach((chatItem) {
                      if (chatItem.name
                          .toLowerCase()
                          .contains(text.toLowerCase())) {
                        setState(() {
                          _filteredChats.add(chatItem);
                        });
                      }
                    });
                  },
                ),
              ),
            )),
            Positioned.fill(
                child: Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 40),
              child: Align(
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
                alignment: Alignment.topLeft,
              ),
            ))
          ],
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() {
    /// Navigate back to home page
    Navigator.of(context).pushReplacementNamed('/app-page');
  }

  @override
  bool get wantKeepAlive => true;
}
