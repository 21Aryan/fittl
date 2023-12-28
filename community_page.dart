import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/Services/CommunityService.dart';
import 'package:fittl/pages/show_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_post_page.dart';

class CommunityPage extends StatefulWidget {
  final String communityId;

  const CommunityPage({super.key, required this.communityId});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {

  final CommunityService _communityService = CommunityService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: Column(
        children: <Widget>[
          _buildCommunityText(),
          Flexible(
              child: _buildPostList()
          ),
          const Divider(height: 1.0),

        ],
      ),
    );
  }

  Widget _buildCommunityText() {
    return FutureBuilder(
      future: _communityService.getCommunityById(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontWeight: FontWeight.bold)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // or any loading indicator
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.data!['communityName'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    snapshot.data!['communityDescription'],
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _openCreatePostModal(context, widget.communityId);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  backgroundColor: const Color(0xFF5A75FF),
                ),
                child:  Row( // Wrap in a Row widget
                  children: [
                    Icon(
                      Icons.add, // Replace with the desired icon
                      color: Colors.white,
                      size: 15.0,
                    ),
                    SizedBox(width: 4.0), // Adjust the spacing between icon and text
                    Text(
                      'Create Post',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildPostList(){
    return StreamBuilder(
      stream: _communityService.getPosts(widget.communityId),
      builder: (context,snapshot){
        if(snapshot.hasError){
          return const Text('error');
        }
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Text('loading');
        }

        return ListView(

            children: snapshot.data!.docs
                .map((doc) => _buildPostListItem(doc)).toList()
        );
      },
    );
  }

  Widget _buildPostListItem(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic> data = documentSnapshot.data()! as Map<String,dynamic>;
    return PostWidget(postId:documentSnapshot.id,communityId: widget.communityId, data: data);
  }

  void _openCreatePostModal(BuildContext context, String communityId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: CreatePostPage(communityId: communityId),
          ),
        );
      },
    );
  }
}

class PostWidget extends StatefulWidget {
  final String postId;
  final String communityId;
  final Map<String, dynamic> data;

  const PostWidget({super.key, 
    required this.postId,
    required this.communityId,
    required this.data,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {

  final CommunityService _communityService = CommunityService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String formatTimestampDifference(Timestamp timestamp) {
    DateTime postTime = timestamp.toDate();
    DateTime currentTime = DateTime.now();

    Duration difference = currentTime.difference(postTime);

    if(difference.inSeconds<60){
      // If the difference is less than a minute, return seconds
      return '${difference.inSeconds}s ago';
    } else if(difference.inMinutes<60){
      // If the difference is less than an hour, return minutes
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      // If the difference is less than a day, return hours
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      // If the difference is less than a week, return days
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      // If the difference is less than a month, return weeks
      int weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      // If the difference is more than a month, return months
      int months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  void _like() async{
    _communityService
        .likePost(widget.data['communityId'],
        widget.postId, _firebaseAuth.currentUser!.uid);
  }

  void _cancelLike() async{
    _communityService
        .cancelLikePost(widget.data['communityId'],
        widget.postId, _firebaseAuth.currentUser!.uid);
  }

  void _viewProfile({required String userId}){
    _openProfilePageModal(context, userId);
  }

  void _openProfilePageModal(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: ShowUserProfile(userId: userId),
          ),
        );
      },
    );
  }



  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      _viewProfile(userId: widget.data['userId']);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          // You can use the user's profile image here
                          backgroundImage: NetworkImage(widget.data['userProfilePic']),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.data['username'],
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              formatTimestampDifference(widget.data['timestamp']),
                              style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data['caption'],
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 8.0),
                  if (widget.data['media'].isNotEmpty)
                    Image.network(
                      widget.data['media'],
                      width: double.infinity,
                      height: 200.0, // Adjust the height as needed
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    (widget.data['likes'].contains(_firebaseAuth.currentUser!.uid)) ? Icons.favorite : Icons.favorite_border,
                    color: widget.data['likes'].contains(_firebaseAuth.currentUser!.uid) ? Colors.red : null,
                  ),
                  onPressed: () {
                    if (!widget.data['likes'].contains(_firebaseAuth.currentUser!.uid)) {
                      _like();
                    } else {
                      _cancelLike();
                    }
                  },
                ),
                Text(
                  '${widget.data['likes'].length} Likes',
                  style: const TextStyle(fontSize: 14.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.data['username'],
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              formatTimestampDifference(widget.data['timestamp']),
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.data['caption'],
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 8.0),
            if (widget.data['media'].isNotEmpty)
              Image.network(
                widget.data['media'],
                width: double.infinity,
                height: 200.0, // Adjust the height as needed
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    (widget.data['likes'].contains(_firebaseAuth.currentUser!.uid)) ? Icons.favorite : Icons.favorite_border,
                    color: widget.data['likes'].contains(_firebaseAuth.currentUser!.uid) ? Colors.red : null,
                  ),
                  onPressed: () {
                    if(!widget.data['likes'].contains(_firebaseAuth.currentUser!.uid)) {
                      _like();
                    }
                    else{
                      _cancelLike();
                    }
                  },
                ),
                Text(
                  '${widget.data['likes'].length} Likes',
                  style: const TextStyle(fontSize: 14.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

