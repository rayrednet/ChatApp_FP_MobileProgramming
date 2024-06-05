import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/constants/firestore_constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoryPageProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  StoryPageProvider({required this.firebaseFirestore, required this.prefs, required this.firebaseStorage});

  Future<List<UserModel>> getStory() async {
    Stream<QuerySnapshot> collectionStream = firebaseFirestore.collection(FirestoreConstants.pathStoryTestCollection).orderBy(FirestoreConstants.idFrom).snapshots();
    String currentId = '';

    late List<UserModel> users = [];
    late List<StoryModel> stories = [];

    int usersIndex = -1;

    final completer = Completer<List<UserModel>>();

    collectionStream.forEach((snapshot)  async {
      for (var collection in snapshot.docs) {
        // Access collection name and potentially subcollections here
        String collectionId = collection.id;
        Map<String, dynamic> data = collection.data()! as Map<String, dynamic>;

        String userId = data['idFrom'];
        String imageUrl = data['content'];
        String caption = data['caption'];

        if(currentId != userId){
          currentId = userId;
          String? nickname = await getNickname(userId);
          String? photoUrl = await getPhoto(userId);

          // print(nickname);
          // print(photoUrl);

          // print(collectionId);
          // print(caption);
          // print(imageUrl);

          stories = [];
          UserModel  new_user = UserModel(userId, stories, nickname!, photoUrl!);
          usersIndex += 1;
          users.add(new_user);

          users[usersIndex].stories.add(StoryModel(imageUrl, caption, collectionId));


        } else {
          // print(collectionId);
          // print(caption);
          // print(imageUrl);

          users[usersIndex].stories.add(StoryModel(imageUrl, caption, collectionId));


        }


      }
      users.forEach((user){
        print(user.userName);
        print(user.imageUrl);
        stories = user.stories;
        stories.forEach((story){
          print(story.caption);
          print(story.imageUrl);
        });
      });

      if (!completer.isCompleted) {
        completer.complete(users);
      }

    });

    return completer.future;




    // final sampleUsers = [
    //   UserModel([
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?ixid=MXwxMjA3fDF8MHxlZGl0b3JpYWwtZmVlZHwxN3x8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes user 1 story 1'),
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1609418426663-8b5c127691f9?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwyNXx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes user 1 story 2'),
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1609444074870-2860a9a613e3?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHw1Nnx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes user 1 story 3'),
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1609504373567-acda19c93dc4?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHw1MHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes User 1 story 4'),
    //   ], "User1",
    //       "https://images.unsplash.com/photo-1609262772830-0decc49ec18c?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwzMDF8fHxlbnwwfHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60"),
    //   UserModel([
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1609439547168-c973842210e1?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHw4Nnx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes user 2 story 1'),
    //   ], "User2",
    //       "https://images.unsplash.com/photo-1601758125946-6ec2ef64daf8?ixid=MXwxMjA3fDF8MHxlZGl0b3JpYWwtZmVlZHwzMjN8fHxlbnwwfHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60"),
    //   UserModel([
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1609421139394-8def18a165df?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwxMDl8fHxlbnwwfHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes User 3 story 1'),
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1609377375732-7abb74e435d9?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwxODJ8fHxlbnwwfHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes User 3 Story 2'),
    //     StoryModel(
    //         "https://images.unsplash.com/photo-1560925978-3169a42619b2?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwyMjF8fHxlbnwwfHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60", 'Tes User 3 Story 3'),
    //   ], "User3",
    //       "https://images.unsplash.com/photo-1609127102567-8a9a21dc27d8?ixid=MXwxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwzOTh8fHxlbnwwfHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60"),
    // ];
    //
    // sampleUsers.forEach((user){
    //   print(user.userName);
    //   print(user.imageUrl);
    //   stories = user.stories;
    //   stories.forEach((story){
    //     print(story.caption);
    //     print(story.imageUrl);
    //   });
    // });
    //
    // return sampleUsers;
  }

  Future<String?> getNickname(String userId) async {
    final CollectionReference users = firebaseFirestore.collection(FirestoreConstants.pathUserCollection);
    try {
      // Get the document for the specific user
      final DocumentSnapshot doc = await users.doc(userId).get();

      // Check if document exists
      if (doc.exists) {
        // Extract the nickname from the data
        return doc['nickname'];
      } else {
        print('User document does not exist');
        return null;
      }
    } catch (error) {
      print('Error fetching nickname: $error');
      return null;
    }
  }

  Future<String?> getPhoto(String userId) async {
    final CollectionReference users = firebaseFirestore.collection(FirestoreConstants.pathUserCollection);
    try {
      // Get the document for the specific user
      final DocumentSnapshot doc = await users.doc(userId).get();

      // Check if document exists
      if (doc.exists) {
        // Extract the nickname from the data
        return doc['photoUrl'];
      } else {
        print('User document does not exist');
        return null;
      }
    } catch (error) {
      print('Error fetching photo: $error');
      return null;
    }
  }

  Future<void> delete(String storyId) async {
    return firebaseFirestore.collection(FirestoreConstants.pathStoryTestCollection).doc(storyId).delete();

    print('Story with ID: $storyId deleted successfully.');

  }

  Future<void> update (String docID, String newCaption){
    return firebaseFirestore.collection(FirestoreConstants.pathStoryTestCollection).doc(docID).update({
      'caption': newCaption,

    });
  }
}

class UserModel {
  UserModel(this.id, this.stories, this.userName, this.imageUrl);
  final String id;
  final List<StoryModel> stories;
  final String userName;
  final String imageUrl;
}

class StoryModel {
  StoryModel(this.imageUrl, this.caption, this.id);
  final String id;
  final String imageUrl;
  final String caption;
}