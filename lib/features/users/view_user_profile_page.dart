import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewUserProfilePage extends StatefulWidget {
  final String userId;
  const ViewUserProfilePage({super.key, required this.userId});

  @override
  State<ViewUserProfilePage> createState() => _ViewUserProfilePageState();
}

class _ViewUserProfilePageState extends State<ViewUserProfilePage> {
  Widget _infoLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _displayCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  void _showReportDialog() {
    final TextEditingController _dialogController = TextEditingController();
    final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 1.5),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Color.fromARGB(255, 255, 166, 1), // Yellow background
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Report User",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dialogController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Enter your reason",
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.black, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Please enter a reason"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            side:
                                const BorderSide(color: Colors.black, width: 2),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () async {
                            if (!_dialogFormKey.currentState!.validate())
                              return;

                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            await FirebaseFirestore.instance
                                .collection('reports')
                                .add({
                              'reportedUserId': widget.userId,
                              'reporterUserId': currentUser?.uid,
                              'reason': _dialogController.text.trim(),
                              'timestamp': FieldValue.serverTimestamp(),
                              'status': 'pending',
                            });

                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Report submitted")),
                            );
                          },
                          child: const Text("Submit"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.black, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text("Player Profile",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
              ],
            ),
            TextButton(
              onPressed: _showReportDialog,
              child: const Text("Report",
                  style: TextStyle(
                      color: Color.fromARGB(255, 211, 47, 47),
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final username = data["username"] ?? "NA";
          final dob = data["dob"] ?? "NA";
          final country = data["country"] ?? "NA";
          final gender = data["gender"] ?? "NA";
          final height = data["height"] ?? "NA";
          final level = data["level"] ?? "5.5";
          final profileImageUrl = data["profileImage"];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: profileImageUrl == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoLabel("username", username),
                          const SizedBox(height: 8),
                          _infoLabel("DOB", dob),
                          const SizedBox(height: 8),
                          _infoLabel("Country", country),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoLabel("Level $level", "Higher intermediate"),
                    _infoLabel("Height", height),
                    _infoLabel("Gender", gender),
                  ],
                ),
                const SizedBox(height: 30),
                _displayCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Adjusted for centering the content
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/photo/achievements.png',
                            height: 40,
                            width: 40,
                          ),
                          SizedBox(width: 10),
                          const Text("Achievements - ",
                              style: TextStyle(fontSize: 16)),
                          const Text("Explorer",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                _displayCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/photo/active_level.png', height: 40),
                      const SizedBox(width: 10),
                      Text("Active Level - ",
                          style: TextStyle(
                            fontSize: 16,
                          )),
                      const Text("Getting Started",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
