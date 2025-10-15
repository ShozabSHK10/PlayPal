import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:playpal/features/chats/group_chat_members_page.dart';
import 'package:playpal/features/users/view_user_profile_page.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  const ChatScreen({required this.matchId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  Map<String, dynamic>? _replyTo;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || user == null) return;

    final senderId = user!.uid;
    final now = Timestamp.now();

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(senderId)
          .get();

      final senderName = userDoc.exists
          ? (userDoc.data()?['username'] ?? "Unknown")
          : "Unknown";

      final messageData = {
        "text": text,
        "senderId": senderId,
        "senderName": senderName,
        "timestamp": now,
      };

      if (_replyTo != null) {
        messageData["replyTo"] = _replyTo;
      }

      await FirebaseFirestore.instance
          .collection("matches")
          .doc(widget.matchId)
          .collection("messages")
          .add(messageData);

      setState(() {
        _messageController.clear();
        _replyTo = null;
      });

      FocusScope.of(context).unfocus();
    } catch (e) {
      print("❌ Error in _sendMessage(): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 59, 59, 59),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Match Discussion",
          style: TextStyle(
            color: Color.fromARGB(255, 154, 154, 154),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color.fromARGB(255, 154, 154, 154)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 12.0), // adjust value as needed
            child: Tooltip(
              message: 'View Members',
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupChatMembersPage(matchId: widget.matchId),
                    ),
                  );
                },
                child: Image.asset(
                  "assets/photo/list.png",
                  height: 24,
                  width: 24,
                  color: Color.fromARGB(255, 154, 154, 154),
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          if (_replyTo != null) _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("matches")
          .doc(widget.matchId)
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("🔥 Firestore stream error: ${snapshot.error}");
          return Center(child: Text("Error loading messages"));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageBubble(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final String text = data["text"] ?? "";
    final String senderId = data["senderId"] ?? "";
    String senderName = data["senderName"] ?? "Unknown";
    final bool isMe = senderId == user?.uid;
    final Timestamp? timestamp = data["timestamp"];
    final Map<String, dynamic>? reply = data["replyTo"];

    String time = "";
    if (timestamp != null) {
      try {
        time = DateFormat.Hm().format(timestamp.toDate());
      } catch (_) {}
    }

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.reply),
                    title: const Text("Reply"),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _replyTo = {
                          "text": text,
                          "senderName": senderName,
                        };
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 2),
                child: GestureDetector(
                  onTap: () {
                    if (senderId != user?.uid) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewUserProfilePage(userId: senderId),
                        ),
                      );
                    }
                  },
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 166, 1),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color.fromARGB(255, 255, 166, 1)
                    : const Color.fromARGB(255, 154, 154, 154),
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reply != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${reply["senderName"]}: ${reply["text"]}",
                        style: const TextStyle(
                            color: Colors.black54, fontStyle: FontStyle.italic),
                      ),
                    ),
                  Text(
                    text,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(
                  color: Color.fromARGB(255, 154, 154, 154), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black26,
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Replying to ${_replyTo!["senderName"]}: ${_replyTo!["text"]}",
              style: const TextStyle(
                  color: Colors.white70, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 154, 154, 154),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    isCollapsed: true, // removes extra padding
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: "Type a Message...",
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 59, 59, 59)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.black), // optional, if needed
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _sendMessage,
                child: Image.asset(
                  'assets/photo/send.png',
                  width: 25,
                  height: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
