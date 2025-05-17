import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chatroom.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to access your inbox.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final participants = List<String>.from(chatRoom['participants']);
              final otherUserId = participants.firstWhere((id) => id != currentUser.uid);
              final lastMessage = chatRoom['lastMessage'] ?? '';
              final lastMessageTime = (chatRoom['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final otherUserName = userData['name'] ?? 'Unknown User';
                  final profilePicUrl = userData['profilePicUrl'] ?? '';

                  // Query unread messages
                  final unreadMessagesStream = FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(chatRoom.id)
                      .collection('messages')
                      .where('read', isEqualTo: false)
                      .where('senderId', isNotEqualTo: currentUser.uid) // Check for unread messages from others
                      .snapshots();

                  return StreamBuilder<QuerySnapshot>(
                    stream: unreadMessagesStream,
                    builder: (context, unreadMessagesSnapshot) {
                      final hasUnreadMessages = unreadMessagesSnapshot.hasData &&
                          unreadMessagesSnapshot.data!.docs.isNotEmpty;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: profilePicUrl.isNotEmpty
                              ? CircleAvatar(
                            backgroundImage: NetworkImage(profilePicUrl),
                          )
                              : CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            otherUserName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('hh:mm a').format(lastMessageTime),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (hasUnreadMessages) // Show the unread indicator
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomPage(
                                  chatRoomId: chatRoom.id,
                                  otherUserId: otherUserId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
