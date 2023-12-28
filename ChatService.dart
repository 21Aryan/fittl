
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/Modals/Message.dart';
import 'package:fittl/Modals/UserProfile.dart';
import 'package:fittl/Services/DatabaseService.dart';
import 'package:flutter/cupertino.dart';

class ChatService extends ChangeNotifier{

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //method to send a message
  Future<void> sendMessage(String receiverId, String message) async{

    //getting current user info
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    UserProfile currentUserProfile = await DatabaseService(uid: currentUserId).getUserProfile(currentUserId);
    final String senderUsername = currentUserProfile.username;
    //creating message
    Message newMessage = Message(
        senderId: currentUserId,
        senderUsername: senderUsername,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp
    );

    //creating unique chatId for 2 users
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatId = ids.join("-");


    await _firestore.collection('chats').doc(chatId).set({
      'users': ids
    });

    //adding to database
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(newMessage.messageToMap());

  }

  //method to receive  a message
  Stream<QuerySnapshot> receiveMessage(String senderId, String receiverId){
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatId = ids.join("-");

    return _firestore
        .collection('chats')
        .doc(chatId).collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();

  }

}