import 'package:flutter/material.dart';
import 'package:playpal/pages/login_page.dart';
import 'register_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
//show login page at first
  bool showLoginPage = true;
//toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: showLoginPage
          ? LoginPage(key: const ValueKey('login'), onTap: togglePages)
          : RegisterPage(key: const ValueKey('register'), onTap: togglePages),
    );
  }
}
