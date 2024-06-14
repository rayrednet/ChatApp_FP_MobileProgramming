import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/providers/providers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_demo/pages/pages.dart';

class UploadStoryPage extends StatefulWidget {
  const UploadStoryPage({super.key});

  @override
  State<UploadStoryPage> createState() => _UploadStoryPageState();
}

class _UploadStoryPageState extends State<UploadStoryPage> {
  late final _authProvider = context.read<AuthProvider>();
  late final String _currentUserId;

  File? _imageFile;
  bool _isLoading = false;
  String _imageUrl = "";

  String prompt = "Please pick an Image";

  String _captionText = "";

  final _listScrollController = ScrollController();

  late final _uploadStoryProvider = context.read<UploadStoryProvider>();

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

  Future<bool> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedXFile = await imagePicker.pickImage(source: ImageSource.gallery).catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
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
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void _onSendMessage(String content, int type, String caption) {
    if (content.trim().isNotEmpty) {
      _uploadStoryProvider.sendMessage(content, type, _currentUserId, caption);
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send', backgroundColor: ColorConstants.greyColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Upload Story',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  _imageFile != null
                      ? Image.file(_imageFile!, width: double.infinity, height: 300, fit: BoxFit.cover)
                      : Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Caption",
                      hintText: "Enter a caption for your image",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    ),
                    maxLength: 200,
                    onChanged: (value) => setState(() => _captionText = value),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _captionText,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (_imageFile != null) {
                          await _uploadFile();
                          print('upload story success');
                          Navigator.pushReplacementNamed(context, '/stories');
                        } else {
                          print('please pick image first');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('Upload',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        bool success = await _pickImage();
                        if (success) {
                          setState(() {
                            prompt = 'Upload Image';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('Pick Image',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
