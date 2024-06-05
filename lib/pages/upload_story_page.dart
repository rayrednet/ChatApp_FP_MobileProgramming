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
            AppConstants.uploadStoryTitle,
            style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 27,
                    ),
                  ),
                  _imageFile != null
                      ? Image.file(_imageFile!, width: 300, height: 400) // Show image if not null
                      : Text(''),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Caption",
                      hintText: "Enter a caption for your image",
                    ),
                    maxLength: 200, // Limit caption to 200 characters
                    onChanged: (value) => setState(() => _captionText = value),
                  ),
                  Text(_captionText),
                ],
              ),
              Positioned(
                  bottom: 20,
                  child: Row(

                    children: [
                      TextButton(
                          onPressed: (){
                            if(_imageFile != null){
                              _uploadFile();
                              print('upload story success');
                              // Navigator.pop(context);
                            } else {
                              print('please pick image first');
                            }

                          },
                          child: Text(
                              'Upload',
                            style: TextStyle(
                              fontSize: 35,
                              color: Colors.black,
                            ),
                          ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.grey[350]),

                        ),
                      ),
                      TextButton(
                          onPressed: () async {
                            bool success = await _pickImage();
                            if(success){
                              setState(() {
                                prompt = 'Upload Image';
                              });
                            }
                          },
                          child: Text(
                              'Pick Image',
                            style: TextStyle(
                              fontSize: 35,
                              color: Colors.black
                            ),
                          ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.grey[350]),

                        ),
                      ),
                    ],
                  )),
            ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.add),
      //   onPressed: () {
      //     _pickImage().then((isSuccess) {
      //       if (isSuccess) _uploadFile();
      //     });
      //   },
      // ),
    );
  }
}
