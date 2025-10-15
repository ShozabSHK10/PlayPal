import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:playpal/features/auth/data/auth_services.dart';
import 'package:playpal/core/widgets/my_button.dart';
import 'package:playpal/core/widgets/my_textfield.dart';
import 'package:playpal/core/widgets/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:playpal/features/auth/forgot_pw_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isResending = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signUserIn() async {
    try {
      // Step 1: Attempt login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      // Step 2: Email verification check
      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Email Not Verified"),
            content: const Text("Please verify your email before logging in."),
            actions: [
              TextButton(
                onPressed: _isResending
                    ? null
                    : () async {
                        setState(() => _isResending = true);
                        await user.sendEmailVerification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Verification email sent."),
                          ),
                        );
                        Navigator.pop(context);
                        Future.delayed(const Duration(seconds: 30), () {
                          if (mounted) setState(() => _isResending = false);
                        });
                      },
                child: Text(
                  _isResending ? "Please wait..." : "Resend Email",
                  style: TextStyle(
                    color: _isResending
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      // Step 3: Check suspension status in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists && userDoc['suspended'] == true) {
        await FirebaseAuth.instance.signOut();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Account Suspended"),
            content: const Text(
                "Your account has been suspended by the admin. Please contact support."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      final userData = userDoc.data();
      await saveFcmToken(user.uid);

      final role = userData?['role']?.toString().toLowerCase();

      print('Logged-in user role: $role');

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.message ?? "Login failed.");
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> saveFcmToken(String uid) async {
    try {
      // Force refresh token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Update the token in Firestore for the user
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token, // Update token in Firestore
        });
        print("✅ FCM Token refreshed and saved for user $uid: $token");
      } else {
        print("❌ Failed to get a valid FCM token");
      }
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 166, 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset('assets/icon/pjl.png', width: 115, height: 115),
                const SizedBox(height: 40),
                const Text(
                  'Welcome back, Let\'s get balling!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                MyButton(text: "Sign In", onTap: signUserIn),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: const [
                      Expanded(
                          child: Divider(thickness: 0.5, color: Colors.black)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Expanded(
                          child: Divider(thickness: 0.5, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      onTap: () => AuthService().signInWithGoogle(),
                      imagePath: 'lib/images/google.png',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Not a member?',
                        style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Register now',
                        style: TextStyle(
                          color: Color.fromARGB(255, 3, 96, 122),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
