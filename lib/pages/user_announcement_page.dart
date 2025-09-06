import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserAnnouncementsPage extends StatelessWidget {
  const UserAnnouncementsPage({super.key});

  Future<bool> _isAnnouncementRead(String announcementId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('readAnnouncements')
        .doc(announcementId)
        .get();

    return doc.exists;
  }

  Future<void> _markAsRead(String announcementId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('readAnnouncements')
        .doc(announcementId)
        .set({'readAt': Timestamp.now()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Announcements",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('sentAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No announcements available."));
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final doc = announcements[index];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final title = data['title'] ?? 'Untitled';
              final message = data['message'] ?? '';
              final timestamp = data['sentAt'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat('MMM d, yyyy – h:mm a')
                      .format(timestamp.toDate())
                  : 'Unknown';

              return FutureBuilder<bool>(
                future: _isAnnouncementRead(id),
                builder: (context, readSnapshot) {
                  final isRead = readSnapshot.data ?? false;

                  return GestureDetector(
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(id);
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      color: Colors.white,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Chip(
                                    label: const Text(
                                      "New",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    backgroundColor:
                                        const Color.fromARGB(255, 255, 166, 1),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color:
                                            Colors.black, // Black outline color
                                        width: 1.2, // Outline width
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              date,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
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
