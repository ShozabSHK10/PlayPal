import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DiscoverPlayersPage extends StatefulWidget {
  const DiscoverPlayersPage({super.key});

  @override
  State<DiscoverPlayersPage> createState() => _DiscoverPlayersPageState();
}

class _DiscoverPlayersPageState extends State<DiscoverPlayersPage> {
  String searchQuery = "";
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Discover Players",
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'user')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allUsers = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final username = data['username']?.toLowerCase() ?? '';
                  return username.contains(searchQuery.toLowerCase()) &&
                      doc.id != currentUser?.uid;
                }).toList();

                if (allUsers.isEmpty) {
                  return const Center(
                      child: Text("No users match your search."));
                }

                return ListView.builder(
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final userDoc = allUsers[index];
                    final data = userDoc.data() as Map<String, dynamic>;
                    final uid = userDoc.id;
                    final username = data['username'] ?? 'Unknown';
                    final country = data['location']?['country'] ?? 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/photo/profile.png'),
                          backgroundColor: Colors.transparent,
                        ),
                        title: Text(username),
                        subtitle: Text("Country: $country"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/viewUserProfile',
                            arguments: uid,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
