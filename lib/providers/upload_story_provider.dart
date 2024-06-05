import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadStoryProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  UploadStoryProvider({required this.firebaseFirestore, required this.prefs, required this.firebaseStorage});

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  void sendMessage(String content, int type, String currentUserId, String caption) {
    final documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathStoryTestCollection)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    final messageChat = Story(
      idFrom: currentUserId,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      caption: caption,
    );

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        messageChat.toJson(),
      );
    });
  }

}