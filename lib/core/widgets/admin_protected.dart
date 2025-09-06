import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProtected extends StatelessWidget {
  final Widget child;

  const AdminProtected({super.key, required this.child});

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists && doc['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == false) {
          return const Scaffold(
            body: Center(child: Text("Access Denied")),
          );
        }

        return child;
      },
    );
  }
}
