import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';

class Story {
  final String idFrom;
  final String timestamp;
  final String content;
  final String caption;

  const Story({
    required this.idFrom,
    required this.timestamp,
    required this.content,
    required this.caption,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: this.idFrom,
      FirestoreConstants.timestamp: this.timestamp,
      FirestoreConstants.content: this.content,
      FirestoreConstants.caption: this.caption,
    };
  }

  factory Story.fromDocument(DocumentSnapshot doc) {
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String timestamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    String caption = doc.get(FirestoreConstants.caption);
    return Story(idFrom: idFrom, timestamp: timestamp, content: content, caption: caption);
  }
}