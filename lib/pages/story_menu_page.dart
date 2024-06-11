import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/providers/providers.dart';
import 'package:flutter_chat_demo/providers/story_page_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_demo/pages/pages.dart';
import 'package:story/story_image.dart';
import 'package:story/story_page_view.dart';

import '../widgets/bottom_navbar.dart';

class StoryMenuPage extends StatefulWidget {
  const StoryMenuPage({super.key});

  @override
  State<StoryMenuPage> createState() => _StoryMenuPageState();
}

class _StoryMenuPageState extends State<StoryMenuPage> {
  late final _authProvider = context.read<AuthProvider>();
  late final _storuMenuProvider = context.read<StoryMenuProvider>();
  late final String _currentUserId;
  List sampleUsers = [];

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
    _getStory();
  }

  int _selectedIndex = 2;

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
        // Current page, no need to navigate
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Future<void> _getStory() async {
    var user = await _storuMenuProvider.getStory();
    setState(() {
      sampleUsers = user;

      sampleUsers.forEach((user) {
        print(user.imageUrl);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Stories',
              style: TextStyle(color: ColorConstants.primaryColor),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadStoryPage(),
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: false, // Ensure centerTitle is set to false
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Max 2 columns per row
          crossAxisSpacing: 10.0, // Horizontal spacing between items
          mainAxisSpacing: 10.0, // Vertical spacing between items
        ),
        itemCount: sampleUsers.length,
        itemBuilder: (context, index) {
          return Card(
            child: InkWell(
              onTap: () {
                print(sampleUsers[index].userName);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StoryPage()),
                );
              },
              child: Image.network(sampleUsers[index].imageUrl),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
