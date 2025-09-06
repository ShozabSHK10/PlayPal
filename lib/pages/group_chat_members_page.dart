import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupChatMembersPage extends StatelessWidget {
  final String matchId;
  const GroupChatMembersPage({required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 59, 59, 59),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Match Members",
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
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('matches').doc(matchId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> memberIds = data['members'] ?? [];

          if (memberIds.isEmpty) {
            return const Center(child: Text('No members in this group.'));
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait(memberIds.map((id) =>
                FirebaseFirestore.instance.collection('users').doc(id).get())),
            builder: (context, memberSnapshot) {
              if (!memberSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final allUsers = memberSnapshot.data!;
              final currentUserDocs =
                  allUsers.where((doc) => doc.id == currentUid).toList();
              final currentUserDoc =
                  currentUserDocs.isNotEmpty ? currentUserDocs.first : null;
              final otherUsers =
                  allUsers.where((doc) => doc.id != currentUid).toList();

              return ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  if (currentUserDoc != null)
                    _buildUserCard(currentUserDoc,
                        isCurrentUser: true, context: context),
                  ...otherUsers.map(
                    (doc) => _buildUserCard(doc,
                        isCurrentUser: false, context: context),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot userDoc,
      {required bool isCurrentUser, required BuildContext context}) {
    final userData = userDoc.data() as Map<String, dynamic>?;
    final username = userData?['username'] ?? 'Unknown';
    final uid = userDoc.id;

    return Card(
      color: isCurrentUser ? const Color.fromARGB(255, 176, 174, 174) : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCurrentUser ? Colors.black12 : Colors.black12,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage('assets/photo/profile.png'),
          backgroundColor: Colors.transparent,
        ),
        title: Text(
          username,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isCurrentUser
            ? null
            : const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: isCurrentUser
            ? null
            : () {
                Navigator.pushNamed(
                  context,
                  '/viewUserProfile',
                  arguments: uid,
                );
              },
      ),
    );
  }
}
