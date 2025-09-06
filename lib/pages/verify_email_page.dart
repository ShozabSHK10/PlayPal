import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playpal/pages/user_info_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isResending = false;
  bool isChecking = false;
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  void resendVerificationEmail() async {
    if (user != null && !user!.emailVerified) {
      setState(() => isResending = true);
      try {
        await user!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent.")),
        );
        await Future.delayed(const Duration(seconds: 10)); // Block for 10s
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send email: $e")),
        );
      }
      if (mounted) setState(() => isResending = false);
    }
  }

  void checkIfVerified() async {
    if (isChecking) return;

    setState(() => isChecking = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No authenticated user found.',
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      await currentUser.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user!.emailVerified) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UserInfoPage()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email not verified yet.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
    } finally {
      if (mounted) setState(() => isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color.fromARGB(255, 255, 166, 0);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/photo/email.png',
                    height: 70,
                    width: 70,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Let's verify your email",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "We’ve sent a verification link to:\n${user?.email ?? 'your email'}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 17, color: Colors.black),
                      children: [
                        const TextSpan(
                          text: "Ready to receive the verification link? ",
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: isResending ? null : resendVerificationEmail,
                            child: Text(
                              isResending ? "Sending..." : "Yes",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: isResending ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  OutlinedButton(
                    onPressed: isChecking ? null : checkIfVerified,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isChecking ? "Checking..." : "I have verified",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
