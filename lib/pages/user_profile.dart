import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/providers/providers.dart';
import 'package:flutter_chat_demo/widgets/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_navbar.dart';
import 'settings_page.dart';
import 'login_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  late final TextEditingController _controllerNickname;
  late final TextEditingController _controllerAboutMe;
  late final TextEditingController _controllerFriendCode;

  String _userId = '';
  String _nickname = '';
  String _aboutMe = '';
  String _avatarUrl = '';
  String _friendCode = '';

  bool _isLoading = false;
  File? _avatarFile;
  late final _settingProvider = context.read<SettingProvider>();
  late final _authProvider = context.read<AuthProvider>();
  late final _homeProvider = context.read<HomeProvider>();

  final _focusNodeNickname = FocusNode();
  final _focusNodeAboutMe = FocusNode();
  final _focusNodeFriendCode = FocusNode();

  final _menus = <MenuSetting>[
    MenuSetting(title: 'Settings', icon: Icons.settings),
    MenuSetting(title: 'Log out', icon: Icons.exit_to_app),
  ];

  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _readLocal();
  }

  void _readLocal() {
    setState(() {
      _userId = _settingProvider.getPref(FirestoreConstants.id) ?? "";
      _nickname = _settingProvider.getPref(FirestoreConstants.nickname) ?? "";
      _aboutMe = _settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      _avatarUrl = _settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
      _friendCode =
          _settingProvider.getPref(FirestoreConstants.friendCode) ?? "";
    });
    _controllerNickname = TextEditingController(text: _nickname);
    _controllerAboutMe = TextEditingController(text: _aboutMe);
    _controllerFriendCode = TextEditingController(text: _friendCode);
  }

  Future<bool> _pickAvatar() async {
    final imagePicker = ImagePicker();
    final pickedXFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
      return null;
    });
    if (pickedXFile != null) {
      final imageFile = File(pickedXFile.path);
      setState(() {
        _avatarFile = imageFile;
        _isLoading = true;
      });
      return true;
    } else {
      return false;
    }
  }

  Future<void> _uploadFile() async {
    final fileName = _userId;
    final uploadTask = _settingProvider.uploadFile(_avatarFile!, fileName);
    try {
      final snapshot = await uploadTask;
      _avatarUrl = await snapshot.ref.getDownloadURL();
      final updateInfo = UserChat(
        id: _userId,
        photoUrl: _avatarUrl,
        nickname: _nickname,
        aboutMe: _aboutMe,
        friendCode: _userId,
      );
      _settingProvider
          .updateDataFirestore(FirestoreConstants.pathUserCollection, _userId,
              updateInfo.toJson())
          .then((_) async {
        await _settingProvider.setPref(FirestoreConstants.photoUrl, _avatarUrl);
        setState(() {
          _isLoading = false;
        });
        showRoundedToast(context, "Profile picture changed");
      }).catchError((err) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  Future<void> _handleUpdateData(String field) async {
    _focusNodeNickname.unfocus();
    _focusNodeAboutMe.unfocus();
    _focusNodeFriendCode.unfocus();

    var doc = await _homeProvider.getStreamFireStore(
        FirestoreConstants.pathUserCollection, _friendCode);

    if (doc.docs.length > 0 &&
        UserChat.fromDocument(doc.docs.last).id != _userId) {
      Fluttertoast.showToast(msg: "Update failed: User ID is already used");
      return;
    }

    setState(() {
      _isLoading = true;
    });
    UserChat updateInfo = UserChat(
      id: _userId,
      photoUrl: _avatarUrl,
      nickname: _nickname,
      aboutMe: _aboutMe,
      friendCode: _friendCode,
    );
    _settingProvider
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, _userId, updateInfo.toJson())
        .then((_) async {
      await _settingProvider.setPref(FirestoreConstants.nickname, _nickname);
      await _settingProvider.setPref(FirestoreConstants.aboutMe, _aboutMe);
      await _settingProvider.setPref(FirestoreConstants.photoUrl, _avatarUrl);
      await _settingProvider.setPref(
          FirestoreConstants.friendCode, _friendCode);

      setState(() {
        _isLoading = false;
      });

      switch (field) {
        case 'name':
          showRoundedToast(context, "Name changed");
          break;
        case 'about':
          showRoundedToast(context, "About changed");
          break;
        case 'id':
          showRoundedToast(context, "ID changed");
          break;
        default:
          showRoundedToast(context, "Changes saved");
      }
    }).catchError((err) {
      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
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
        // Current page, no need to navigate
        break;
    }
  }

  void showRoundedToast(BuildContext context, String message) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50.0,
        left: MediaQuery.of(context).size.width * 0.2,
        width: MediaQuery.of(context).size.width * 0.6,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 10, 11, 37).withOpacity(0.75),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Center(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry
    Overlay.of(context)?.insert(overlayEntry);

    // Remove the overlay entry after the duration
    Future.delayed(Duration(seconds: 2)).then((_) => overlayEntry.remove());
  }

  void _onItemMenuPress(MenuSetting choice) {
    if (choice.title == 'Log out') {
      _handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => SettingsPage()));
    }
  }

  Future<void> _handleSignOut() async {
    await _authProvider.handleSignOut();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<MenuSetting>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
      ),
      onSelected: _onItemMenuPress,
      itemBuilder: (_) {
        return _menus.map(
          (choice) {
            return PopupMenuItem<MenuSetting>(
              value: choice,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                ),
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
                ),
              ),
            );
          },
        ).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Your Profile',
            style: TextStyle(color: ColorConstants.primaryColor),
          ),
        ),
        centerTitle: true,
        actions: [_buildPopupMenu()],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                CupertinoButton(
                  onPressed: () {
                    _pickAvatar().then((isSuccess) {
                      if (isSuccess) _uploadFile();
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(20),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipOval(
                          child: _avatarFile == null
                              ? _avatarUrl.isNotEmpty
                                  ? Image.network(
                                      _avatarUrl,
                                      fit: BoxFit.cover,
                                      width: 150,
                                      height: 150,
                                      errorBuilder: (_, __, ___) {
                                        return Icon(
                                          Icons.account_circle,
                                          size: 150,
                                          color: ColorConstants.greyColor,
                                        );
                                      },
                                      loadingBuilder:
                                          (_, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          width: 150,
                                          height: 150,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: ColorConstants.themeColor,
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
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
                                    )
                                  : Icon(
                                      Icons.account_circle,
                                      size: 150,
                                      color: ColorConstants.greyColor,
                                    )
                              : Image.file(
                                  _avatarFile!,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              _pickAvatar().then((isSuccess) {
                                if (isSuccess) _uploadFile();
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 45, 59, 185)
                                    .withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Input
                Column(
                  children: [
                    // Username
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person,
                                  color: ColorConstants.primaryColor),
                              SizedBox(width: 10),
                              Text(
                                'Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: ColorConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              SizedBox(width: 32),
                              Expanded(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      primaryColor:
                                          ColorConstants.primaryColor),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Sweetie',
                                      hintStyle: TextStyle(
                                          color: ColorConstants.greyColor),
                                    ),
                                    controller: _controllerNickname,
                                    onChanged: (value) {
                                      _nickname = value;
                                    },
                                    focusNode: _focusNodeNickname,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _handleUpdateData('name');
                                },
                                child: Icon(Icons.edit,
                                    color: ColorConstants.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // About me
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info,
                                  color: ColorConstants.primaryColor),
                              SizedBox(width: 10),
                              Text(
                                'About',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: ColorConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              SizedBox(width: 32),
                              Expanded(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      primaryColor:
                                          ColorConstants.primaryColor),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'No status',
                                      hintStyle: TextStyle(
                                          color: ColorConstants.greyColor),
                                    ),
                                    controller: _controllerAboutMe,
                                    onChanged: (value) {
                                      _aboutMe = value;
                                    },
                                    focusNode: _focusNodeAboutMe,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _handleUpdateData('about');
                                },
                                child: Icon(Icons.edit,
                                    color: ColorConstants.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // User ID
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5EFCE8),
                            const Color(0xFF736EFE),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.vpn_key,
                                  color: ColorConstants.primaryColor),
                              SizedBox(width: 10),
                              Text(
                                'User ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: ColorConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(left: 32.0),
                            child: Text(
                              'You can update your user ID by clicking the pencil icon.',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorConstants.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                margin: EdgeInsets.only(left: 32.0),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                              255, 212, 212, 212)
                                          .withOpacity(0.1),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                            primaryColor:
                                                ColorConstants.primaryColor),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 0),
                                            hintText: 'User ID',
                                            hintStyle: TextStyle(
                                                color:
                                                    ColorConstants.greyColor),
                                          ),
                                          controller: _controllerFriendCode,
                                          readOnly: false,
                                          onChanged: (value) {
                                            _friendCode = value;
                                          },
                                          focusNode: _focusNodeFriendCode,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.copy,
                                          color: ColorConstants.primaryColor),
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: _friendCode));
                                        showRoundedToast(context,
                                            "User ID copied to clipboard");
                                      },
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _handleUpdateData('id');
                                      },
                                      child: Icon(Icons.edit,
                                          color: ColorConstants.primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),

                // Remove the Update button here
              ],
            ),
            padding: EdgeInsets.only(left: 15, right: 15),
          ),

          // Loading
          Positioned(child: _isLoading ? LoadingView() : SizedBox.shrink()),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
