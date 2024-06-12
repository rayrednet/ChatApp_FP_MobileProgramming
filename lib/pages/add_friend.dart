import 'package:flutter/material.dart';

class AddFriendPage extends StatefulWidget {
  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  TextEditingController _friendIdController = TextEditingController();
  String? _searchResult;
  bool _isLoading = false;
  // Mock function to simulate searching for a user by ID.
  Future<Map<String, dynamic>?> _searchById(String id) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    if (id == "validUserId") {
      return {
        "profilePictureUrl": "https://example.com/profile.jpg",
        "name": "Valid User"
      };
    } else {
      return null;
    }
  }

  void _searchFriend() async {
    setState(() {
      _isLoading = true;
    });
    var result = await _searchById(_friendIdController.text);
    setState(() {
      _isLoading = false;
      _searchResult = result != null ? "found" : "not_found";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Search'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _friendIdController,
              decoration: InputDecoration(
                hintText: "Enter your friend's ID",
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _searchFriend,
              child: Text(
                'Search',
                style: TextStyle(color: const Color.fromARGB(255, 13, 73, 122)),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _searchResult != null
                    ? _searchResult == "found"
                        ? Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                    "https://example.com/profile.jpg"),
                                radius: 40,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Valid User",
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  // Handle send friend request logic
                                },
                                child: Text('Send Friend Request'),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              'User not found',
                              style: TextStyle(fontSize: 18, color: Colors.red),
                            ),
                          )
                    : Container(),
          ],
        ),
      ),
    );
  }
}
