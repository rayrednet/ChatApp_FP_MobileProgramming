import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/pages/home_page.dart';
import 'package:flutter_chat_demo/pages/contacts.dart';
import 'package:flutter_chat_demo/pages/story_menu_page.dart';
import 'package:flutter_chat_demo/pages/user_profile.dart';
import 'package:flutter_chat_demo/pages/upload_story_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  PageController _pageController = PageController();
  int _selectedIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: <Widget>[
          HomePage(), // Chat
          ContactsPage(), // Friends
          StoryMenuPage(), // Stories
          UserProfilePage(), // Profile
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.amp_stories),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        selectedItemColor: Color.fromARGB(
            255, 41, 60, 170), // Set the selected item color to white
        unselectedItemColor: const Color.fromARGB(179, 163, 163,
            163), // Set the unselected item color to a lighter shade of white
        showSelectedLabels: true, // Show labels for selected items
        showUnselectedLabels: true, // Show labels for unselected items
        type: BottomNavigationBarType
            .fixed, // Fix the navigation bar type to avoid shifting
      ),
    );
  }
}
