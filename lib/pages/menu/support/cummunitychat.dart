import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wash_it/Dimensions/dimensions.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    signInAnonymously(); // Sign in the user anonymously
  }

  // Submit message to Firestore
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String message = _messageController.text.trim();
      User? user = _auth.currentUser;

      FirebaseFirestore.instance.collection('chats').add({
        'text': message,
        'createdAt': Timestamp.now(),
        'userId': user!.uid,
      });

      _messageController.clear(); // Clear input field
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Chat', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/washit.png?alt=media&token=b5f311f4-c60c-4184-badc-7ce22af262e5', // Provide your image URL here
                ),
                //fit: BoxFit.cover,
              ),
            ),
          ),
          // Chat content
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
                    if (chatSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final chatDocs = chatSnapshot.data!.docs;
                    return ListView.builder(
                      reverse: true, // Show newest messages at the bottom
                      itemCount: chatDocs.length,
                      itemBuilder: (ctx, index) {
                        final chatDoc = chatDocs[index];
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(chatDoc['userId'])
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return ListTile(title: Text("Loading..."));
                            }
                            if (userSnapshot.hasError) {
                              return ListTile(title: Text("Error loading user"));
                            }
                            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add padding here
                                child: MessageBubble(
                                  userName: "Unknown User",
                                  message: chatDoc['text'],
                                  isMe: chatDoc['userId'] == _auth.currentUser!.uid,
                                ),
                              );
                            }

                            final userData = userSnapshot.data!;
                            final userName = userData['name'] ?? "Unknown";

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add padding here
                              child: MessageBubble(
                                userName: userName,
                                message: chatDoc['text'],
                                isMe: chatDoc['userId'] == _auth.currentUser!.uid,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Send a message...',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radius30),
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radius30),
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.Width10),
                    CircleAvatar(
                      radius: Dimensions.radius30,
                      backgroundColor: Colors.green,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<User?> signInAnonymously() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("Error signing in anonymously: $e");
      return null;
    }
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final String userName;
  final bool isMe;

  MessageBubble({required this.userName, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.green : Colors.black87,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMe
                        ? [Colors.green, Colors.greenAccent]
                        : [Colors.black12, Colors.grey.shade100],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 5,
                    )
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: isMe ? Radius.circular(Dimensions.radius12) : Radius.circular(0),
                    topRight: !isMe ? Radius.circular(Dimensions.radius12) : Radius.circular(0),
                    bottomLeft: Radius.circular(Dimensions.radius12),
                    bottomRight: Radius.circular(Dimensions.radius12),
                  ),
                ),
                width: 220,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
