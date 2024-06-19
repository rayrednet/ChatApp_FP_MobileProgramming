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

class StoryPage extends StatefulWidget {
  const StoryPage(
      {super.key,
      required int initialPageIndex,
      required int initialStoryIndex});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  late ValueNotifier<IndicatorAnimationCommand> indicatorAnimationController;
  late final _storyProvider = context.read<StoryPageProvider>();

  List sampleUsers = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();
  String _newCaption = '';

  late final _authProvider = context.read<AuthProvider>();
  late final String _currentUserId;

  Future<void> _getStory() async {
    var user = await _storyProvider.getStory();
    setState(() {
      sampleUsers = user;
    });
  }

  int currentUserIndex = 0;

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
    _getStory();

    indicatorAnimationController = ValueNotifier<IndicatorAnimationCommand>(
        IndicatorAnimationCommand.resume);
  }

  @override
  void dispose() {
    indicatorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoryPageView(
        itemBuilder: (context, pageIndex, storyIndex) {
          final user = sampleUsers[pageIndex];
          final story = user.stories[storyIndex];
          return Stack(
            children: [
              Positioned.fill(
                child: Container(color: Colors.black),
              ),
              Positioned.fill(
                child: StoryImage(
                  key: ValueKey(story.imageUrl),
                  imageProvider: NetworkImage(
                    story.imageUrl,
                  ),
                  fit: BoxFit.fitWidth,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 44, left: 8),
                child: Row(
                  children: [
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(user.imageUrl),
                          fit: BoxFit.cover,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      user.userName,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        gestureItemBuilder: (context, pageIndex, storyIndex) {
          final user = sampleUsers[pageIndex];
          final story = user.stories[storyIndex];
          return Stack(children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            if (pageIndex >= 0)
              Positioned(
                bottom: 20,
                child: Center(
                  child: ElevatedButton(
                    child: const Text('Info'),
                    onPressed: () async {
                      indicatorAnimationController.value =
                          IndicatorAnimationCommand.pause;
                      await showModalBottomSheet(
                        context: context,
                        builder: (context) => SizedBox(
                          height: MediaQuery.of(context).size.height /
                              4, // Adjust the height here
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  story.caption,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                                if (user.id == _currentUserId)
                                  Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Enter New Caption'),
                                              content: Form(
                                                key: _formKey,
                                                child: TextFormField(
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'New Caption',
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter a caption';
                                                    }
                                                    return null;
                                                  },
                                                  onSaved: (newValue) =>
                                                      setState(() =>
                                                          _newCaption =
                                                              newValue!),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    if (_formKey.currentState!
                                                        .validate()) {
                                                      _formKey.currentState!
                                                          .save();
                                                      await _storyProvider
                                                          .update(story.id,
                                                              _newCaption);
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text('Update'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: Text('Update'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _storyProvider.delete(story.id);
                                          setState(() {
                                            Navigator.pop(
                                              context, // Close the bottom sheet
                                            );
                                          });
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                      indicatorAnimationController.value =
                          IndicatorAnimationCommand.resume;
                    },
                  ),
                ),
              ),
          ]);
        },
        indicatorAnimationController: indicatorAnimationController,
        initialStoryIndex: (pageIndex) {
          if (pageIndex == 0) {
            return 0;
          }
          return 0;
        },
        pageLength: sampleUsers.length,
        storyLength: (int pageIndex) {
          return sampleUsers[pageIndex].stories.length;
        },
        onPageLimitReached: () {
          Navigator.pop(context);
        },
      ),
    );
    ;
  }
}
