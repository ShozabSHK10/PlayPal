import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatsPage extends StatefulWidget {
  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Group Chats",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("matches")
            .where("members", arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No group chats available",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          var matches = snapshot.data!.docs;

          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            itemBuilder: (context, index) {
              var match = matches[index];
              return _buildChatItem(match);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(DocumentSnapshot match) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("matches")
          .doc(match.id)
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        String lastMessage = "No messages yet";
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          lastMessage = snapshot.data!.docs.first["text"];
        }

        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black,
                    width: 1.2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 255, 166, 1),
                  child: Icon(Icons.group, color: Colors.white),
                ),
              ),
              title: Text(
                match["matchTitle"],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                lastMessage,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(matchId: match.id),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: Colors.grey.shade400,
                thickness: 0.8,
                height: 0,
              ),
            ),
          ],
        );
      },
    );
  }
}
