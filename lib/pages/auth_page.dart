import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/pages/user_info_page.dart';
import 'package:playpal/pages/home_page.dart';
import 'package:playpal/pages/verify_email_page.dart';
import 'package:playpal/pages/login_or_register_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  final List<String> adminEmails = const [
    'admin1@gmail.com',
  ];

  Future<Map<String, dynamic>> _getUserInfo(User user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      // Create new user doc if it doesn't exist
      final isAdmin = adminEmails.contains(user.email);
      await userRef.set({
        'email': user.email,
        'name': user.displayName ?? '',
        'role': isAdmin ? 'admin' : 'user',
        'onboardingCompleted': false,
      });
      return {
        'role': isAdmin ? 'admin' : 'user',
        'onboardingCompleted': false,
      };
    }

    // Return stored role and onboarding status
    return {
      'role': doc['role'],
      'onboardingCompleted': doc['onboardingCompleted'] ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const LoginOrRegisterPage();
        }

        return FutureBuilder(
          future: user.reload(),
          builder: (context, reloadSnapshot) {
            if (reloadSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!user.emailVerified) {
              return const VerifyEmailPage();
            }

            return FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(user),
              builder: (context, setupSnapshot) {
                if (setupSnapshot.connectionState == ConnectionState.waiting ||
                    !setupSnapshot.hasData ||
                    !setupSnapshot.data!.containsKey('role')) {
                  // Keep loading until Firestore returns actual data
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = setupSnapshot.data!;
                final isSetupComplete = data['onboardingCompleted'] ?? false;
                final role =
                    data['role']; // No fallback — must wait for real value

                if (!isSetupComplete) {
                  return const UserInfoPage();
                } else {
                  return HomePage();
                }
              },
            );
          },
        );
      },
    );
  }
}
