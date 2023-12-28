import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/Services/DatabaseService.dart';
import 'package:fittl/pages/chat_page.dart';
import 'package:fittl/pages/new_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {

  bool showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // Remove app bar shadow
        backgroundColor: Colors.white, // Match background color
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 27.0,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      _openNewChatModal(context);
                    },
                    borderRadius: BorderRadius.circular(50.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A75FF),
                        // Set your desired button color
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'New Chat ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: Colors.black,
                    onPressed: () {
                      // Handle search icon click
                      setState(() {
                        showSearchBar = !showSearchBar;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8.0),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Adjust the duration as needed
            height: showSearchBar ? 50.0 : 0.0, // Set the initial and final heights
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: showSearchBar? Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search',
                      ),
                onChanged: (query) {
                  setState(() {
              });
            },
              ),
          ):Container(),
          ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildUserList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: _databaseService.getChatList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // or any loading indicator
        }
        if (snapshot.hasError) {
          return const Text('Error fetching data');
        }
        if (!snapshot.hasData) {
          return const Text('No data available');
        }

        // If you've reached here, you have a valid stream
        return StreamBuilder<QuerySnapshot>(
          stream: snapshot.data,
          builder: (context, streamSnapshot) {
            if (streamSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // or any loading indicator
            }
            if (streamSnapshot.hasError) {
              return Container();
            }

            var docs = streamSnapshot.data!.docs;
            if (docs.isEmpty) {
              return const Text('No friends available');

            }
            if (_searchController.text.isNotEmpty) {
              docs = docs.where((doc) {
                var username = doc['username'] as String;
                return username.toLowerCase().contains(_searchController.text.toLowerCase());
              }).toList();
            }

            return ListView(
              children: docs
                  .map<Widget>((doc) => _buildUserListItem(doc))
                  .toList(),
            );
          },

        );
      },
    );
  }




  Widget _buildUserListItem(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic> data = documentSnapshot.data()! as Map<String,
        dynamic>;
    final formattedTime = DateFormat('hh:mm a').format(DateTime.now());

    // // Fetch the latest message for this chat
    // CollectionReference messagesCollection = FirebaseFirestore.instance
    //     .collection('messages');
    // Query latestMessageQuery = messagesCollection
    //     .where('receiverId', isEqualTo: documentSnapshot.id)
    //     .orderBy('timestamp', descending: true)
    //     .limit(1);
    //
    // return StreamBuilder<QuerySnapshot>(
    //     stream: latestMessageQuery.snapshots(),
    //     builder: (context, snapshot) {
    //       if (snapshot.hasError) {
    //         print("Error fetching latest message: ${snapshot.error}");
    //         return const Text('Error');
    //       }
    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //         return const Text('Loading');
    //       }
    //
    //       var latestMessage = snapshot.data!.docs.isNotEmpty ? snapshot.data!
    //           .docs.first : null;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 15.0, vertical: 3.0),
            leading: CircleAvatar(
              radius: 40,
              // You can use the user's profile image here
              backgroundImage: NetworkImage(data['profileURL']),
            ),
            title: Container(
              padding: const EdgeInsets.only(right: 22.0),
              // Adjust the right padding as needed
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    data['username'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   Text(
                    // Format the timestamp as needed
                    formattedTime,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 5.0), // Add top padding
              child: Text(
                "hiiii",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(
                        title: data['username'],
                        receiverId: documentSnapshot.id,
                        profileURL: data['profileURL'],
                      ),
                ),
              );
            },
            // Add a Divider between each ListTile
            // Or you can use other decorations to separate the chat items
            //tileColor: Colors.grey[200],
            //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            //trailing: Icon(Icons.chevron_right),
          );
        }

  void _openNewChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: const NewChat(),
          ),
        );
      },
    );
  }
    //);
  }
//}

