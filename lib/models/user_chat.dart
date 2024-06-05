import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/constants.dart';

class UserChat {
  final String id;
  final String photoUrl;
  final String nickname;
  final String aboutMe;
  final String friendCode;

  const UserChat({required this.id, required this.photoUrl, required this.nickname, required this.aboutMe, required this.friendCode});

  Map<String, String> toJson() {
    return {
      FirestoreConstants.nickname: nickname,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.friendCode: friendCode,
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    String aboutMe = "";
    String photoUrl = "";
    String nickname = "";
    String friendCode = "";
    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (_) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (_) {}
    try {
      nickname = doc.get(FirestoreConstants.nickname);
    } catch (_) {}
    try {
      friendCode = doc.get(FirestoreConstants.friendCode);
    } catch (_) {}
    return UserChat(
      id: doc.id,
      photoUrl: photoUrl,
      nickname: nickname,
      aboutMe: aboutMe,
      friendCode: friendCode,
    );
  }
}
