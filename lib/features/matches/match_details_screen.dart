import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class MatchDetailsScreen extends StatefulWidget {
  final String matchId;

  MatchDetailsScreen({required this.matchId});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  File? _paymentImage;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo access is required.")),
      );
      return;
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);

      final exists = await file.exists();
      final size = await file.length();

      if (!exists || size == 0) {
        print("❌ Picked file is empty or inaccessible");
        return;
      }

      setState(() {
        _paymentImage = file;
      });

      print("📸 Image selected: ${file.path}");
    } else {
      print("⚠️ No image selected");
    }
  }

  Future<void> _uploadAndJoinMatch(DocumentSnapshot matchDoc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _paymentImage == null) return;

    final matchId = widget.matchId;

    // Correct Firebase path
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('match_screenshots/$matchId/${user.uid}/screenshot.jpg');

    setState(() => _uploading = true);

    try {
      print("🔁 Starting upload from: ${_paymentImage!.path}");

      // Step 1: Upload to Storage
      await storageRef.putFile(_paymentImage!);
      print("✅ Image uploaded to Firebase Storage");

      final imageUrl = await storageRef.getDownloadURL();
      print("🌐 Download URL: $imageUrl");

      // Step 2: Write to /matches/{matchId}/payments/{userId}
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('payments')
          .doc(user.uid)
          .set({
        'screenshot': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Payment document created");

      // Step 3: Update match members
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'members': FieldValue.arrayUnion([user.uid])
      });
      print("✅ Added user to match members");

      // Step 4: Add to group chat if exists
      final chatDoc = await FirebaseFirestore.instance
          .collection('groupChats')
          .where('matchId', isEqualTo: matchId)
          .limit(1)
          .get();

      if (chatDoc.docs.isNotEmpty) {
        final chatId = chatDoc.docs.first.id;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You’ve successfully joined the match!")),
        );

        await FirebaseFirestore.instance
            .collection('groupChats')
            .doc(chatId)
            .update({
          'members': FieldValue.arrayUnion([user.uid])
        });
        print("Added to group chat");

        Navigator.pushReplacementNamed(context, '/groupChat',
            arguments: chatId);
      } else {
        Navigator.pop(context);
      }
    } catch (e, stack) {
      print("🔥 Upload failed: $e");
      print("📌 Stack trace: $stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed. Please try again.")),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<String?> _getUsername(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data()?['username'] ?? uid;
    } catch (e) {
      return uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        title: const Text(
          "Match Details",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Match not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['matchTitle'] ?? "Match";
          final date = (data['matchDateTime'] as Timestamp).toDate();
          final players = data['players'] ?? '';
          final fees = int.tryParse(data['matchFees'].toString()) ?? 0;
          final location = data['matchLocation'] ?? 'Unknown';
          final members = List<String>.from(data['members'] ?? []);
          final creator = data['creatorId'] ?? '';

          final maxPlayers = players == '6v6'
              ? 12
              : players == '7v7'
                  ? 14
                  : 16;
          final feePerPlayer = ((fees / maxPlayers).ceil() / 10).ceil() * 10;

          final isFull = members.length >= maxPlayers;
          final alreadyJoined = user != null && members.contains(user.uid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _infoRow("Location", location),
                _infoRow("Date & Time",
                    DateFormat('EEE, MMM d • hh:mm a').format(date)),
                _infoRow("Format", players),
                _infoRow("Your Share of Fee", "Rs $feePerPlayer"),
                _infoRow("Split Info", "Rs $fees / $maxPlayers players"),
                FutureBuilder<String?>(
                  future: _getUsername(creator),
                  builder: (context, creatorSnap) {
                    if (creatorSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text("Created by: loading..."),
                      );
                    }
                    return _infoRow("Created by", creatorSnap.data ?? creator);
                  },
                ),
                const Divider(height: 30),
                Text("Members Joined (${members.length}):",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...members.map((uid) => FutureBuilder<String?>(
                      future: _getUsername(uid),
                      builder: (context, snap) {
                        final name = snap.data ?? uid;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("- $name",
                                style: TextStyle(color: Colors.grey[800])),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/viewUserProfile',
                                    arguments: uid);
                              },
                              child: const Text(
                                "View Profile",
                                style: TextStyle(
                                    color: Color.fromARGB(255, 223, 145, 2)),
                              ),
                            ),
                          ],
                        );
                      },
                    )),
                const Divider(height: 30),
                if (alreadyJoined)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "You’ve already joined this match.",
                      style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                Text("Upload Payment Screenshot",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: alreadyJoined ? null : _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: _paymentImage == null
                        ? const Center(child: Text("Tap to upload screenshot"))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                Image.file(_paymentImage!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_uploading ||
                            _paymentImage == null ||
                            isFull ||
                            alreadyJoined)
                        ? null
                        : () {
                            _uploadAndJoinMatch(snapshot.data!);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _uploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isFull
                                ? "Match is Full"
                                : alreadyJoined
                                    ? "Already Joined"
                                    : "Join Match",
                            style: const TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(label + ": ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
