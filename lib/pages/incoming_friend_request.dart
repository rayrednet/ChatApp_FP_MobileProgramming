import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/color_constants.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/menu_setting.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/pages/pages.dart';
import 'package:flutter_chat_demo/providers/auth_provider.dart';
import 'package:flutter_chat_demo/providers/friend_provider.dart';
import 'package:flutter_chat_demo/providers/home_provider.dart';
import 'package:flutter_chat_demo/utils/debouncer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class IncomingRequestsPage extends StatefulWidget {
  @override
  State<IncomingRequestsPage> createState() => _IncomingRequestsPageState();
}

class _IncomingRequestsPageState extends State<IncomingRequestsPage> {
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

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for the incoming friend requests data
    final List<Map<String, String>> incomingRequests = [
      {'name': 'burger 124', 'status': 'Incoming Friend Request'},
      {'name': 'burger 149', 'status': 'Incoming Friend Request'},
      {'name': 'burger 195', 'status': 'Incoming Friend Request'},
      {'name': 'burger 231', 'status': 'Incoming Friend Request'},
      {'name': 'burger 263', 'status': 'Incoming Friend Request'},
      {'name': 'burger 339', 'status': 'Incoming Friend Request'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Incoming Friend Requests'),
      ),
      body: incomingRequests.isEmpty
          ? Center(
              child: Text(
                'No incoming friend requests',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : StreamBuilder<List<DocumentSnapshot>>(
                    stream: _friendProvider.getStreamFireStore(
                      FirestoreConstants.pathUserCollection,
                      FirestoreConstants.pathFriendIn,
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
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    'https://via.placeholder.com/150'), // Placeholder image
                              ),
                              title: Text(userChat.nickname),
                              subtitle: Text(userChat.aboutMe),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () {
                                      _friendProvider.acceptRequest(
                                        FirestoreConstants.pathUserCollection,
                                        FirestoreConstants.pathFriendCollection,
                                        FirestoreConstants.pathFriendOut,
                                        FirestoreConstants.pathFriendIn,
                                        _currentUserId,
                                        userChat.id
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () {
                                      // Decline friend request logic
                                    },
                                  ),
                                ],
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
          // : 
    );
  }
}
