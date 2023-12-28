import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../Modals/Community.dart';
import '../Modals/Post.dart';
import '../Modals/UserProfile.dart';
import 'DatabaseService.dart';
import 'package:async/async.dart';

class CommunityService extends ChangeNotifier{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //method to create a new Post
  Future<void> createPost(String communityId, String caption, File? media) async{

    //getting current user info
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    String url="";
    if(media!=null){
      final fileName = '$communityId-post-${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = FirebaseStorage.instance.ref();
      Reference refDir = ref.child('communities').child(communityId).child('posts');
      Reference refImg = refDir.child(fileName);

      try{
        await refImg.putFile(media);
        url = await refImg.getDownloadURL();

      }catch(e){
        print(e);
      }

    }
    UserProfile currentUserProfile = await DatabaseService(uid: currentUserId).getUserProfile(currentUserId);
    final String currentUsername = currentUserProfile.username;

    Map<String, dynamic>? communityMap = await getCommunityMapById(communityId);
    
    //creating post
    Post newPost = Post(
        userId: currentUserId,
        username: currentUsername,
        communityId: communityId,
        caption: caption,
        timestamp: timestamp,
        media: url,
        userProfilePic: currentUserProfile.profilePicture!,
        communityName: communityMap['communityName'],
        communityDisplayPicture: communityMap['displayPicture'], likes: [],
    );


    //adding to database
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .add(newPost.postToMap());

  }


  //method to get posts by community ID
  Stream<QuerySnapshot> getPosts(String communityId){

    return _firestore
        .collection('communities')
        .doc(communityId).collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();

  }

  Future<List<Post>> getAllPosts() async {
    List<Community> communities = await exploreCommunities();

    List<Post> posts = [];

    for (var community in communities) {
      var communitySnapshot = await _firestore
          .collection('communities')
          .doc(community.communityId)
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      for(var data in communitySnapshot.docs){
        Post post = Post(
            postId: data.id,
            userId: data['userId'],
            username: data['username'],
            userProfilePic: data['userProfilePic'],
            communityId: data['communityId'],
            communityName: data['communityName'],
            communityDisplayPicture: data['communityDisplayPicture'],
            caption: data['caption'],
            timestamp: data['timestamp'],
            likes: data['likes'],
            media: data['media']
        );
        posts.add(post);
        log(post.caption);
      }

    }
    posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return posts;
  }


  Future<List<Community>> exploreCommunities() async{
    var userDoc = await FirebaseFirestore.instance
        .collection('user-profile')
        .doc(_firebaseAuth.currentUser!.uid).get();

    //Set to store community id of already joined/owned communities
    Set<String> myCommunities = <String>{};
    var joinedCommunities = userDoc.data()!['joinedCommunities'];
    var ownedCommunities = userDoc.data()!['ownedCommunities'];
    if(joinedCommunities!=null) {
      myCommunities.addAll(List<String>.from(joinedCommunities));
    }
    if(ownedCommunities!=null) {
      myCommunities.addAll(List<String>.from(ownedCommunities));
    }

    List<Community> communityList = [];
    var communitySnapshot = await FirebaseFirestore.instance.collection('communities').get();

    for(var community in communitySnapshot.docs){
      var communityId = community.id;
      //if(!myCommunities.contains(communityId)){
        var communityMap = community.data();
        Community c = Community(
            communityId: communityId,
            communityName: communityMap['communityName'],
            communityDescription: communityMap['communityDescription'],
            displayPicture: communityMap['displayPicture'],
            dateCreated: communityMap['dateCreated'].toDate(),
            ownerId: communityMap['ownerId'],
            members: communityMap['members'].cast<String>(),
            tags: communityMap['tags'].cast<String>()
        );
        communityList.add(c);
      //}
    }

    return communityList;
  }


  Future<DocumentSnapshot> getCommunityById(String communityId) async {
    return await _firestore
        .collection('communities')
        .doc(communityId).get();
  }

  Future<Map<String,dynamic>> getCommunityMapById(String communityId) async {
    var communityDoc =  await _firestore.collection('communities').doc(communityId).get();
    Map<String, dynamic> communityMap = communityDoc.data()!;
    return communityMap;
  }

  Future likePost(String communityId, String postId, String userId) async{
    var postDoc = await _firestore
        .collection('communities')
        .doc(communityId).collection('posts').doc(postId).get();
    var postMap = postDoc.data();

    List<dynamic> likes = postMap!['likes'];

    likes.add(userId);
    _firestore
        .collection('communities')
        .doc(communityId).collection('posts').doc(postId).update({
            'likes': likes
        });
  }

  Future cancelLikePost(String communityId, String postId, String userId) async{
    var postDoc = await _firestore
        .collection('communities')
        .doc(communityId).collection('posts').doc(postId).get();
    var postMap = postDoc.data();

    List<dynamic> likes = postMap!['likes'];

    if(likes.contains(userId)) {
      likes.remove(userId);
    }
    _firestore
        .collection('communities')
        .doc(communityId).collection('posts').doc(postId).update({
      'likes': likes
    });
  }



}