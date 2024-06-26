import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/pages/pages.dart';
import 'package:flutter_chat_demo/providers/friend_provider.dart';
import 'package:flutter_chat_demo/providers/providers.dart';
import 'package:flutter_chat_demo/utils/utils.dart';
import 'package:flutter_chat_demo/widgets/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'new_chat_page.dart';
import 'new_group_page.dart';
import 'add_friend.dart';
import 'incoming_friend_request.dart';
import 'contact_details.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

enum ChatOptions { newChat, newGroup }

Map<ChatOptions, String> optionsText = {
  ChatOptions.newChat: "New chat",
  ChatOptions.newGroup: "New group",
};

Map<ChatOptions, IconData> optionsIcons = {
  ChatOptions.newChat: Icons.chat,
  ChatOptions.newGroup: Icons.group,
};

String _selectedChatType = 'All';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _listScrollController = ScrollController();

  int _limit = 20;
  final _limitIncrement = 20;
  String _textSearch = "";
  bool _isLoading = false;

  late final _authProvider = context.read<AuthProvider>();
  late final _homeProvider = context.read<HomeProvider>();
  late final _friendProvider = context.read<FriendProvider>();
  late final String _currentUserId;

  final _searchDebouncer = Debouncer(milliseconds: 300);
  final _btnClearController = StreamController<bool>();
  final _searchBarController = TextEditingController();

  final _menus = <MenuSetting>[
    MenuSetting(title: 'Settings', icon: Icons.settings),
    MenuSetting(title: 'Log out', icon: Icons.exit_to_app),
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (_authProvider.userFirebaseId?.isNotEmpty == true) {
      _currentUserId = _authProvider.userFirebaseId!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (_) => false,
      );
    }
    _registerNotification();
    _configLocalNotification();
    _listScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _btnClearController.close();
    _searchBarController.dispose();
    _listScrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  void _registerNotification() {
    _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      print('onMessage: $message');
      if (message.notification != null) {
        _showNotification(message.notification!);
      }
      return;
    });

    _firebaseMessaging.getToken().then((token) {
      print('push token: $token');
      if (token != null) {
        _homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection,
            _currentUserId, {'pushToken': token});
      }
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void _configLocalNotification() {
    final initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final initializationSettingsIOS = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _scrollListener() {
    if (_listScrollController.offset >=
            _listScrollController.position.maxScrollExtent &&
        !_listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void _onItemMenuPress(MenuSetting choice) {
    if (choice.title == 'Log out') {
      _handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => SettingsPage()));
    }
  }

  void _showNotification(RemoteNotification remoteNotification) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.dfa.flutterchatdemo'
          : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    final iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    print(remoteNotification);

    await _flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      platformChannelSpecifics,
      payload: null,
    );
  }

  Future<void> _handleSignOut() async {
    await _authProvider.handleSignOut();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/friends');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/stories');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _createNewChat() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          100, 600, 20, 100), // Adjust the position as needed
      items: ChatOptions.values.map((ChatOptions option) {
        return PopupMenuItem<ChatOptions>(
          value: option,
          child: Row(
            children: [
              Icon(optionsIcons[option], color: Colors.black),
              SizedBox(width: 10),
              Text(optionsText[option]!),
            ],
          ),
        );
      }).toList(),
    ).then((ChatOptions? selectedOption) {
      if (selectedOption == null) return;

      switch (selectedOption) {
        case ChatOptions.newChat:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewChatPage()),
          );
          break;
        case ChatOptions.newGroup:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewGroupPage()),
          );
          break;
      }
    });
  }

  void _navigateToAddFriend() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddFriendPage()),
    );
  }

  void _navigateToIncomingRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IncomingRequestsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatterBox'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _navigateToAddFriend,
            tooltip: 'Add Friend',
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: _navigateToIncomingRequests,
            tooltip: 'Incoming Friend Requests',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // _buildStory(),
                _buildSearchBar(),
                Expanded(
                  child: StreamBuilder<List<DocumentSnapshot>>(
                    stream: _friendProvider.getStreamFireStore(
                      FirestoreConstants.pathUserCollection,
                      FirestoreConstants.pathFriendCollection,
                      _currentUserId,
                      _textSearch,
                    ),
                    builder: (_, snapshot) {
                      print(snapshot.hasData);
                      if (snapshot.hasData) {
                        if ((snapshot.data?.length ?? 0) > 0) {
                          return ListView.builder(
                            padding: EdgeInsets.all(10),
                            itemBuilder: (_, index) =>
                                _buildItem(snapshot.data?[index]),
                            itemCount: snapshot.data?.length,
                            controller: _listScrollController,
                          );
                        } else {
                          return Center(
                            child: Text("No recent chats. Start a new chat!"),
                          );
                        }
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            color: ColorConstants.themeColor,
                          ),
                        );
                      }
                    },
                  ),
                ),
                // _buildUploadStoryButton(),
              ],
            ),
            Positioned(
              child: _isLoading ? LoadingView() : SizedBox.shrink(),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _createNewChat,
      //   backgroundColor: Color.fromARGB(255, 46, 75, 133),
      //   child: Icon(Icons.chat, color: Colors.white),
      //   shape: CircleBorder(), // Ensures the button is circular
      // ),
    );
  }

  Widget _buildUploadStoryButton() {
    return Container(
      child: BottomNavigationBar(
        onTap: (int index) {
          setState(() {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryMenuPage(),
                ),
              );
            }
            // Navigate to corresponding page based on index
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Story',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: ColorConstants.greyColor, size: 20),
          SizedBox(width: 5),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: _searchBarController,
              onChanged: (value) {
                _searchDebouncer.run(
                  () {
                    if (value.isNotEmpty) {
                      _btnClearController.add(true);
                      setState(() {
                        _textSearch = value;
                      });
                    } else {
                      _btnClearController.add(false);
                      setState(() {
                        _textSearch = "";
                      });
                    }
                  },
                );
              },
              decoration: InputDecoration.collapsed(
                hintText: 'Search by name',
                hintStyle:
                    TextStyle(fontSize: 13, color: ColorConstants.greyColor),
              ),
              style: TextStyle(fontSize: 13),
            ),
          ),
          StreamBuilder<bool>(
            stream: _btnClearController.stream,
            builder: (_, snapshot) {
              return snapshot.data == true
                  ? GestureDetector(
                      onTap: () {
                        _searchBarController.clear();
                        _btnClearController.add(false);
                        setState(() {
                          _textSearch = "";
                        });
                      },
                      child: Icon(Icons.clear_rounded,
                          color: ColorConstants.greyColor, size: 20))
                  : SizedBox.shrink();
            },
          ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ColorConstants.greyColor2,
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<MenuSetting>(
      onSelected: _onItemMenuPress,
      itemBuilder: (_) {
        return _menus.map(
          (choice) {
            return PopupMenuItem<MenuSetting>(
                value: choice,
                child: Row(
                  children: [
                    Icon(
                      choice.icon,
                      color: ColorConstants.primaryColor,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      choice.title,
                      style: TextStyle(color: ColorConstants.primaryColor),
                    ),
                  ],
                ));
          },
        ).toList();
      },
    );
  }

  Widget _buildItem(DocumentSnapshot? document) {
    if (document != null) {
      final userChat = UserChat.fromDocument(document);
      if (userChat.id == _currentUserId) {
        return SizedBox.shrink();
      } else {
        return Container(
          child: Slidable(
            endActionPane: ActionPane(
              motion: ScrollMotion(),
              extentRatio:
                  0.25, // Adjust this value to make the delete button smaller
              children: [
                SlidableAction(
                  onPressed: (context) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Remove Contact'),
                          content: Text(
                              'Are you sure you want to remove ${userChat.nickname}?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _friendProvider.removeFriend(
                                  FirestoreConstants.pathUserCollection,
                                  FirestoreConstants.pathFriendCollection,
                                  _currentUserId,
                                  userChat.id,
                                );
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text('Remove'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: TextButton(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactDetailsPage(
                            contact: userChat,
                          ),
                        ),
                      );
                    },
                    child: ClipOval(
                      child: userChat.photoUrl.isNotEmpty
                          ? Image.network(
                              userChat.photoUrl,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              loadingBuilder: (_, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: ColorConstants.themeColor,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, object, stackTrace) {
                                return Icon(
                                  Icons.account_circle,
                                  size: 40,
                                  color: ColorConstants.greyColor,
                                );
                              },
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 40,
                              color: ColorConstants.greyColor,
                            ),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Text(
                              '${userChat.nickname}',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 3),
                          ),
                          Container(
                            child: Text(
                              '${userChat.aboutMe}',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(left: 10),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                if (Utilities.isKeyboardShowing(context)) {
                  Utilities.closeKeyboard();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      arguments: ChatPageArguments(
                        peerId: userChat.id,
                        peerAvatar: userChat.photoUrl,
                        peerNickname: userChat.nickname,
                      ),
                    ),
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.transparent),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
            ),
          ),
          margin: EdgeInsets.only(bottom: 10, left: 10, right: 10),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }
}
