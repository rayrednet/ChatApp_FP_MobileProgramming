import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/models/menu_setting.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/pages/login_page.dart';
import 'package:flutter_chat_demo/pages/pages.dart';
import 'package:flutter_chat_demo/providers/auth_provider.dart';
import 'package:flutter_chat_demo/providers/friend_provider.dart';
import 'package:flutter_chat_demo/providers/home_provider.dart';
import 'package:flutter_chat_demo/utils/debouncer.dart';
import 'package:flutter_chat_demo/utils/utilities.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_navbar.dart';
import '../constants/constants.dart';
import 'add_friend.dart';
import 'incoming_friend_request.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'contact_details.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
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

  // int _selectedIndex = 1;
  TextEditingController _searchController = TextEditingController();
  List<bool> _isSelected = [true, false];

  // Dummy data for friends and groups
  List<Map<String, String>> _friends = [
    {"name": "John Doe", "status": "Online"},
    {"name": "Jane Smith", "status": "Offline"},
  ];

  List<Map<String, String>> _groups = [
    {"name": "Flutter Devs", "status": "Active"},
    {"name": "Gaming Squad", "status": "Inactive"},
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 1:
        // Current page, no need to navigate
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/stories');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
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
    List<Map<String, String>> displayList = _isSelected[0] ? _friends : _groups;

    return Scaffold(
      appBar: AppBar(
        title: Text('Friend List'),
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.search,
                          color: ColorConstants.greyColor, size: 20),
                      SizedBox(width: 5),
                      Expanded(
                        child: TextFormField(
                          textInputAction: TextInputAction.search,
                          controller: _searchController,
                          decoration: InputDecoration.collapsed(
                            hintText: 'Search by name',
                            hintStyle: TextStyle(
                                fontSize: 13, color: ColorConstants.greyColor),
                          ),
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      StreamBuilder<bool>(
                        stream: Stream.value(_searchController.text.isNotEmpty),
                        builder: (_, snapshot) {
                          return snapshot.data == true
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  child: Icon(Icons.clear_rounded,
                                      color: ColorConstants.greyColor,
                                      size: 20))
                              : SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(16),
                    selectedBorderColor: ColorConstants.primaryColor,
                    selectedColor: Colors.white,
                    fillColor: ColorConstants.primaryColor,
                    color: ColorConstants.greyColor,
                    constraints: BoxConstraints(minHeight: 35, minWidth: 80),
                    isSelected: _isSelected,
                    onPressed: (int index) {
                      setState(() {
                        for (int buttonIndex = 0;
                            buttonIndex < _isSelected.length;
                            buttonIndex++) {
                          if (buttonIndex == index) {
                            _isSelected[buttonIndex] = true;
                          } else {
                            _isSelected[buttonIndex] = false;
                          }
                        }
                      });
                    },
                    children: <Widget>[
                      Text('Friends'),
                      Text('Groups'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: displayList.isEmpty
                ? Center(child: Text('No friends'))
                : StreamBuilder<List<DocumentSnapshot>>(
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
                          itemCount: snapshot.data?.length,
                          itemBuilder: (context, index) {
                            final request = snapshot.data?[index];
                            if(request == null) return SizedBox.shrink();
                            final userChat = UserChat.fromDocument(snapshot.data![index]);
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContactDetailsPage(
                                        contact: userChat),
                                  ),
                                );
                              },
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
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog
                                                  },
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      displayList.removeAt(
                                                          index); // Remove the contact
                                                    });
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog
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
                                startActionPane: ActionPane(
                                  motion: ScrollMotion(),
                                  extentRatio:
                                      0.25, // Adjust this value to make the chat button smaller
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
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
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      icon: Icons.chat,
                                      label: 'Chat',
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: ClipOval(
                                    child: Image.network(
                                      userChat.photoUrl,
                                      fit: BoxFit.cover,
                                      width: 50,
                                      height: 50,
                                      loadingBuilder: (_, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: ColorConstants.themeColor,
                                              value: loadingProgress.expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, object, stackTrace) {
                                        return CircleAvatar(
                                          child: Icon(
                                              _isSelected[0] ? Icons.person : Icons.group),
                                        );
                                      },
                                    ),
                                  ), 
                                  title: Text(userChat.nickname),
                                  subtitle: Text(userChat.aboutMe),
                                ),
                              ),
                            );
                          },
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
                // 
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
