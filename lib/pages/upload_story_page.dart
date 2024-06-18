import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/providers/providers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_demo/pages/pages.dart';
import 'package:flutter_chat_demo/pages/story_menu_page.dart'; // Ensure this import is correct

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

class UploadStoryPage extends StatefulWidget {
  const UploadStoryPage({super.key, required void Function(dynamic story) onStoryUploaded});

  @override
  State<UploadStoryPage> createState() => _UploadStoryPageState();
}

class _UploadStoryPageState extends State<UploadStoryPage> {
  late final _authProvider = context.read<AuthProvider>();
  late final String _currentUserId;

  File? _imageFile;
  bool _isLoading = false;
  String _imageUrl = "";

  String _captionText = "";

  final _listScrollController = ScrollController();

  late final _uploadStoryProvider = context.read<UploadStoryProvider>();

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
  }

  Future<bool> _pickImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedXFile =
        await imagePicker.pickImage(source: source).catchError((err) {
      showRoundedToast(context, err.toString());
      return null;
    });
    if (pickedXFile != null) {
      final imageFile = File(pickedXFile.path);
      setState(() {
        _imageFile = imageFile;
        _isLoading = true;
      });
      return true;
    } else {
      return false;
    }
  }

  Future<void> _uploadFile() async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final uploadTask = _uploadStoryProvider.uploadFile(_imageFile!, fileName);
    try {
      final snapshot = await uploadTask;
      _imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _isLoading = false;
        _onSendMessage(_imageUrl, TypeMessage.image, _captionText);
        print('sending story');
      });
      showRoundedToast(context, "Upload Successful!");
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
      });
      showRoundedToast(context, e.message ?? e.toString());
    }
  }

  void _onSendMessage(String content, int type, String caption) {
    if (content.trim().isNotEmpty) {
      _uploadStoryProvider.sendMessage(content, type, _currentUserId, caption);
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      showRoundedToast(context, 'Nothing to send');
    }
  }

  Widget _buildOptionButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add to story',
        ),
      ),
      body: SafeArea(
        child: _imageFile == null
            ? Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Choose your media source for your story:",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildOptionButton('Camera', Icons.camera,
                                  () => _pickImage(ImageSource.camera)),
                              SizedBox(height: 20),
                              _buildOptionButton('Gallery', Icons.photo,
                                  () => _pickImage(ImageSource.gallery)),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Center(
                    child: Container(
                      color: Colors.black54,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter a caption for your image",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          fillColor: Colors.black54,
                          filled: true,
                        ),
                        maxLength: 200,
                        onChanged: (value) =>
                            setState(() => _captionText = value),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_imageFile != null) {
                          await _uploadFile();
                          print('upload story success');
                          showRoundedToast(context, "Upload successful!");
                          Navigator.pop(
                              context); // Navigate back to StoryMenuPage
                        } else {
                          showRoundedToast(
                              context, "Please pick an imge first.");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 84, 128, 224),
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text(
                        'Upload',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
