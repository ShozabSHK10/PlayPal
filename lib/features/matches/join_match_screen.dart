import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class JoinMatchScreen extends StatefulWidget {
  final String matchId;
  final int maxPlayers;
  final List members;

  const JoinMatchScreen({
    super.key,
    required this.matchId,
    required this.maxPlayers,
    required this.members,
  });

  @override
  State<JoinMatchScreen> createState() => _JoinMatchScreenState();
}

class _JoinMatchScreenState extends State<JoinMatchScreen> {
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _joinMatch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedImage == null) return;

    setState(() => _loading = true);

    try {
      // ✅ Check again if already joined or full
      final matchSnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .get();

      final data = matchSnapshot.data();
      if (data == null) throw Exception("Match not found.");

      final currentMembers = List<String>.from(data['members'] ?? []);
      final playersText = data['players'] ?? "6v6";
      final max = playersText == "6v6"
          ? 12
          : playersText == "7v7"
              ? 14
              : 16;

      if (currentMembers.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You’ve already joined this match.")),
        );
        return;
      }
      if (currentMembers.length >= max) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Match is already full.")),
        );
        return;
      }

      // ✅ Upload screenshot
      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('match_payments/${widget.matchId}/$fileName');

      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();

      // ✅ Save to Firestore
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('payments')
          .doc(user.uid)
          .set({
        'screenshotUrl': downloadUrl,
        'verified': false,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Joined successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Join match error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong.")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Join Match"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _selectedImage == null
                ? Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text("No screenshot selected."),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, height: 200),
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.upload),
              label: Text("Select Screenshot"),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _selectedImage != null && !_loading ? _joinMatch : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              ),
              child: _loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Confirm & Join"),
            ),
          ],
        ),
      ),
    );
  }
}
