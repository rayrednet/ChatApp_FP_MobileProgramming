import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:rxdart/rxdart.dart';

class FriendProvider {
  final FirebaseFirestore firebaseFirestore;

  FriendProvider({required this.firebaseFirestore});

  Future<void> updateDataFirestore(String collectionPath, String path, Map<String, String> dataNeedUpdate) {
    return firebaseFirestore.collection(collectionPath).doc(path).update(dataNeedUpdate);
  }

  void _clearRequest(String collectionPath, String friendOutPath, String friendInPath, String currentUserId, String peerId) {
    firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendInPath)
      .doc(peerId).delete();

    firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendOutPath)
      .doc(peerId).delete();

    firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendInPath)
      .doc(currentUserId).delete();
    
    firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendOutPath)
      .doc(currentUserId).delete();
  }

  void sendRequest(String collectionPath, String friendOutPath, String friendInPath, String currentUserId, String peerId) async {
    var outFriend = await firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendOutPath)
      .doc(peerId).get();

    var inFriend = await firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendInPath)
      .doc(peerId).get();

    var peerOut = await firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendOutPath)
      .doc(currentUserId).get();

    var peerIn = await firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendInPath)
      .doc(currentUserId).get();

    if(inFriend.exists || outFriend.exists || peerIn.exists || peerOut.exists) {
      _clearRequest(collectionPath, friendOutPath, friendInPath, currentUserId, peerId);
    }

    await firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendOutPath)
      .doc(peerId).set({});

    await firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendInPath)
      .doc(currentUserId).set({});

    outFriend = await firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendOutPath)
      .doc(peerId).get();

    inFriend = await firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendInPath)
      .doc(currentUserId).get();

    if(outFriend.exists ^ inFriend.exists) {
      _clearRequest(collectionPath, friendOutPath, friendInPath, currentUserId, peerId);
      return;
    }
  }

  void acceptRequest(String collectionPath, String friendPath, String friendOutPath, String friendInPath, String currentUserId, String peerId) async {
    var inFriendRef = firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendInPath)
      .doc(peerId);
    
    var outFriendRef = firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendOutPath)
      .doc(currentUserId);

    var inFriend = await inFriendRef.get();
    var outFriend = await outFriendRef.get();

    print('${inFriend.exists} ${outFriend.exists}');

    if(inFriend.exists ^ outFriend.exists) {
      _clearRequest(collectionPath, friendOutPath, friendInPath, currentUserId, peerId);
      return;
    }

    await inFriendRef.delete();
    await outFriendRef.delete();

    firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendPath)
      .doc(peerId).set({});

    firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendPath)
      .doc(currentUserId).set({});
  }

  void declineRequest(String collectionPath, String friendPath, String friendOutPath, String friendInPath, String currentUserId, String peerId) {
    firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendInPath)
      .doc(peerId).delete();
    
    firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendOutPath)
      .doc(currentUserId).delete();
  }

  void removeFriend(String collectionPath, String friendPath, String currentUserId, String peerId) async {
    await firebaseFirestore.collection(collectionPath)
      .doc(currentUserId)
      .collection(friendPath)
      .doc(peerId).delete();

    await firebaseFirestore.collection(collectionPath)
      .doc(peerId)
      .collection(friendPath)
      .doc(currentUserId).delete();
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
