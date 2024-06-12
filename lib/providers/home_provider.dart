import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/firestore_constants.dart';

class HomeProvider {
  final FirebaseFirestore firebaseFirestore;

  HomeProvider({required this.firebaseFirestore});

  Future<void> updateDataFirestore(String collectionPath, String path, Map<String, String> dataNeedUpdate) {
    return firebaseFirestore.collection(collectionPath).doc(path).update(dataNeedUpdate);
  }

  Future<QuerySnapshot> getStreamFireStore(String pathCollection, String textSearch) {
    return firebaseFirestore
      .collection(pathCollection)
      .limit(1)
      .where(FirestoreConstants.id, isEqualTo: textSearch)
      .get();
  }
}
