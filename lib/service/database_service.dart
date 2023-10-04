import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  DatabaseService({this.uid});
  final String? uid;

  // reference for our collections
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection('groups');

  // updating the userdata
  Future updateUserData(String fullName, String email) async {
    return await userCollection.doc(uid).set({
      'fullName': fullName,
      'email': email,
      'groups': [],
      'profilePic': '',
      'uid': uid,
    });
  }

  // update the userProfile
  Future userProfileUpdate(String url) async {
    return await userCollection.doc(uid).update({
      'profilePic': url,
    });
  }

  // getting user data
  Future gettingUserData(String email) async {
    final QuerySnapshot snapshot =
        await userCollection.where('email', isEqualTo: email).get();
    return snapshot;
  }

  // getting user group
  Future<Stream<DocumentSnapshot<Object?>>> getUserGroups() async {
    return userCollection.doc(uid).snapshots();
  }

  // creating group
  Future createGroup(String userName, String id, String groupName) async {
    final DocumentReference groupDocumentReference = await groupCollection.add({
      'groupName': groupName,
      'groupIcon': '',
      'admin': '${id}_$userName',
      'members': [],
      'groupId': '',
      'recentMessage': '',
      'recentMessageSender': '',
    });

    // update the group memebers
    await groupDocumentReference.update({
      'members': FieldValue.arrayUnion(['${uid}_$userName']),
      'groupId': groupDocumentReference.id,
    });

    final DocumentReference userDocumentReference = userCollection.doc(uid);
    return await userDocumentReference.update({
      'groups':
          FieldValue.arrayUnion(['${groupDocumentReference.id}_$groupName']),
    });
  }

  // getting the chats
  Future<Stream<QuerySnapshot<Map<String, dynamic>>>> getChats(
      String groupId) async {
    return groupCollection
        .doc(groupId)
        .collection('messages')
        .orderBy('time')
        .snapshots();
  }

  // getting group admin
  Future getGroupAdmins(String groupId) async {
    final DocumentReference d = groupCollection.doc(groupId);
    final DocumentSnapshot documentSnapshot = await d.get();
    return documentSnapshot['admin'];
  }

  // get group members
  Future<Stream<DocumentSnapshot<Object?>>> getGroupMembers(groupId) async {
    return groupCollection.doc(groupId).snapshots();
  }

  // search
  Future<QuerySnapshot<Object?>> searchByName(String groupName) {
    return groupCollection.where('groupName', isEqualTo: groupName).get();
  }

  // return boolean value
  Future<bool> isUserJoined(
    String groupname,
    String groupId,
    String userName,
  ) async {
    final DocumentReference userDocumentReference = userCollection.doc(uid);
    final DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    final List<dynamic> groups = await documentSnapshot['groups'];
    if (groups.contains('${groupId}_$groupname')) {
      return true;
    } else {
      return false;
    }
  }

  // toggling the group join/exit
  Future toggleGroupJoin(
    String groupId,
    String userName,
    String groupName,
  ) async {
    final DocumentReference userDocumentReference = userCollection.doc(uid);
    final DocumentReference groupDocumentReference =
        groupCollection.doc(groupId);
    final DocumentSnapshot documentSnapshot = await userDocumentReference.get();
    final List<dynamic> groups = await documentSnapshot['groups'];

    if (groups.contains('${groupId}_$groupName')) {
      await userDocumentReference.update({
        'groups': FieldValue.arrayRemove(['${groupId}_$groupName']),
      });
      await groupDocumentReference.update({
        'groups': FieldValue.arrayRemove(['${uid}_$userName']),
      });
    } else {
      await userDocumentReference.update({
        'groups': FieldValue.arrayUnion(['${groupId}_$groupName']),
      });
      await groupDocumentReference.update({
        'members': FieldValue.arrayUnion(['${uid}_$userName']),
      });
    }
  }

  // send message
  sendMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    groupCollection.doc(groupId).collection('messages').add(chatMessageData);
    groupCollection.doc(groupId).update({
      'recentMessage': chatMessageData['message'],
      'recentMessageSender': chatMessageData['sender'],
      'recentMessageTime': chatMessageData['time'].toString(),
    });
  }
}
