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

class StoryMenuPage extends StatefulWidget {
  const StoryMenuPage({super.key});

  @override
  State<StoryMenuPage> createState() => _StoryMenuPageState();
}

class _StoryMenuPageState extends State<StoryMenuPage> {
  late final _authProvider = context.read<AuthProvider>();
  late final _storyMenuProvider = context.read<StoryMenuProvider>();
  late final _settingProvider = context.read<SettingProvider>();
  late final String _currentUserId;
  String? _currentUserProfileImage;
  List sampleUsers = [];

  @override
  void initState() {
    super.initState();
    if (_authProvider.userFirebaseId?.isNotEmpty == true) {
      _currentUserId = _authProvider.userFirebaseId!;
      _currentUserProfileImage =
          _settingProvider.getPref(FirestoreConstants.photoUrl);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (_) => false,
      );
    }
    _getStory();
  }

  Future<void> _getStory() async {
    var user = await _storyMenuProvider.getStory();
    if(!mounted) return;
    setState(() {
      sampleUsers = user;

      sampleUsers.forEach((user) {
        print(user.imageUrl);
      });
    });
  }

  void _addUploadedStory(dynamic uploadedStory) {
    if(!mounted) return;
    setState(() {
      sampleUsers.insert(0, uploadedStory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stories',
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: false,
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Max 2 columns per row
          crossAxisSpacing: 10.0, // Horizontal spacing between items
          mainAxisSpacing: 10.0, // Vertical spacing between items
        ),
        itemCount: sampleUsers.length + 1, // Include current user's story card
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15), // Set the desired radius here
              ),
              child: InkWell(
                onTap: () async {
                  final uploadedStory = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadStoryPage(
                        onStoryUploaded: (story) => _addUploadedStory(story),
                      ),
                    ),
                  );
                  if (uploadedStory != null) {
                    _addUploadedStory(uploadedStory);
                  }
                },
                child: Stack(
                  children: [
                    _currentUserProfileImage != null
                        ? Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(_currentUserProfileImage!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 50, color: Colors.white),
                            SizedBox(height: 10),
                            Text('Add to your story',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15), // Set the desired radius here
              ),
              child: InkWell(
                onTap: () {
                  print(sampleUsers[index - 1].userName); // Adjust index by 1
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryPage(
                        initialPageIndex:
                            index - 1, // Pass the initial page index
                        initialStoryIndex:
                            0, // Pass the initial story index (default to 0)
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    sampleUsers[index - 1].imageUrl, // Adjust index by 1
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
