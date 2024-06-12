import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  int _selectedIndex = 1;
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
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailsPage(
                                  contact: displayList[index]),
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
                                            'Are you sure you want to remove ${displayList[index]['name']}?'),
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
                                  // Add your chat action here
                                },
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                icon: Icons.chat,
                                label: 'Chat',
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                  _isSelected[0] ? Icons.person : Icons.group),
                            ),
                            title: Text(displayList[index]['name']!),
                            subtitle: Text(displayList[index]['status']!),
                          ),
                        ),
                      );
                    },
                  ),
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
