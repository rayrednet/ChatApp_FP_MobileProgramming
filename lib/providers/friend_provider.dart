import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:rxdart/rxdart.dart';

class FriendProvider {
  final FirebaseFirestore firebaseFirestore;

  FriendProvider({required this.firebaseFirestore});

  Future<void> updateDataFirestore(String collectionPath, String path, Map<String, String> dataNeedUpdate) {
    return firebaseFirestore.collection(collectionPath).doc(path).update(dataNeedUpdate);
  }

  void sendRequest(String collectionPath, String friendOutPath, String friendInPath, String currentUserId, String peerId) {
    firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendOutPath)
      .doc(peerId);

    firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendInPath)
      .doc(currentUserId);
  }

  void acceptRequest(String collectionPath, String friendPath, String friendInPath, String currentUserId, String peerId) {
    firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendPath)
      .doc(peerId).delete();

    firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendPath)
      .doc(peerId);
  }

  Stream<List<DocumentSnapshot>>  getStreamFireStore(String pathCollection, String friendPath, String currentUserId, String? textSearch) async* {
    List<DocumentSnapshot> snapshots = [];
    Stream<QuerySnapshot<Map<String, dynamic>>> idSnapshots = firebaseFirestore.collection(pathCollection)
      .doc(currentUserId)
      .collection(friendPath)
      .snapshots();

    await for (var idSnapshot in idSnapshots) {
      List<String> ids = idSnapshot.docs.map((doc) => doc.id).toList();
      snapshots = [];

      for (var id in ids) {
          DocumentSnapshot snapshot = await firebaseFirestore.collection(pathCollection).doc(id).get();
          snapshots.add(snapshot);
      }
      
      yield snapshots;
    }
  }
}
