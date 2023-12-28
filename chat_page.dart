import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fittl/Services/ChatService.dart';
import 'package:fittl/pages/show_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title, required this.receiverId, required this.profileURL});

  final String receiverId;
  final String title;
  final String profileURL;

  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sendMessage() async {
    if (_textController.text.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverId, _textController.text);
      ChatMessage message = ChatMessage(
        text: _textController.text,
        isSender: true,
      );

      setState(() {
        _messages.insert(0, message);
      });
      _textController.clear();
    }
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

  void _handleSubmitted(String text) {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isSender: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: AppBar(
            toolbarHeight: 80,
            leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 27.0),
                  child: Icon(Icons.arrow_back_ios, color: Colors.grey),
                )),
            title: GestureDetector(
              onTap:(){
                _viewProfile(userId: widget.receiverId);
            },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.profileURL),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            elevation: 0,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30))),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEFEFEF),
          image: DecorationImage(
            image: AssetImage('assets/images/ChatBkg.png'), // Replace with the path to your image asset
            fit: BoxFit.cover, // Adjust the BoxFit as needed
          ),
        ),
        child: Column(
          children: <Widget>[
            Flexible(child: _buildMessageList()),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35))),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.receiveMessage(
          _firebaseAuth.currentUser!.uid, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('loading');
        }

        return ListView(
            reverse: true,

            children: snapshot.data!.docs.reversed
                .map((doc) => _buildMessageListItem(doc))
                .toList());
      },
    );
  }

  Widget _buildMessageListItem(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic> data =
        documentSnapshot.data()! as Map<String, dynamic>;
    return ChatMessage(
        text: data['message'],
        isSender: data['senderId'] == _firebaseAuth.currentUser!.uid);
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).canvasColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            const Icon(Icons.add_circle_outline, color: Colors.grey),
            const SizedBox(width: 15),
            Flexible(
              child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.mic, color: Colors.grey,),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0),
                    hintText: 'Send a message',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color.fromRGBO(238, 238, 238, 1.0),
                  )),
            ),
            IconButton(
              icon: const Icon(
                Icons.send,
                color: Color(0xFF5A75FF),
              ),
              onPressed: () => sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({super.key, required this.text, required this.isSender});

  final String text;
  final bool isSender;
  final formattedTime = DateFormat('hh:mm a').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: isSender? const EdgeInsets.only(right: 10.0) : const EdgeInsets.only(left: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isSender ? const Color(0xFF5A75FF) : Colors.white,
                    borderRadius: isSender ? const BorderRadius.only(
                        topLeft: Radius.circular(17),
                        topRight: Radius.circular(0),
                        bottomLeft: Radius.circular(17),
                        bottomRight: Radius.circular(17))
                    :   const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(17),
                        bottomLeft: Radius.circular(17),
                        bottomRight: Radius.circular(17)),
                  ),
                  padding:const EdgeInsets.only(
                          right: 22, top: 10, bottom: 10, left: 18),
                  child: SizedBox(
                    width: text.length > 20 ? 220: null,
                    child: Text(
                      text,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: isSender ? Colors.white : Colors.black,
                          fontSize: 15
                      ),
                      softWrap: true,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedTime,
                      style:
                          const TextStyle(fontSize: 10.0, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    if(isSender)
                      Image.asset(
                      'assets/images/GreyDoubleTick.png', // Replace with the path to your custom check image
                      width: 12, // Adjust the width as needed
                      height: 12, // Adjust the height as needed
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
