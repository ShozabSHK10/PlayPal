import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'faq_page.dart';
import 'help_support_page.dart';
import 'terms_page.dart';
import 'privacy_policy_page.dart';
import 'about_us_page.dart';
import 'user_info_page.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSettingsOption(
              Icons.support_agent, "Help and Support", context),
          _buildSettingsOption(Icons.chat_bubble_outline, "FAQs", context),
          _buildSettingsOption(
              Icons.article_outlined, "Terms and Condition", context),
          _buildSettingsOption(Icons.lock_outline, "Privacy Policy", context),
          _buildSettingsOption(Icons.info_outline, "About us", context),
          _buildSettingsOption(Icons.tune, "Update Preferences", context),
          _buildSettingsOption(Icons.logout, "Logout", context,
              isDestructive: true), // Set destructive to true for Logout
        ],
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, BuildContext context,
      {bool isDestructive = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: isDestructive
                ? Color.fromARGB(
                    255, 178, 12, 0) // Red color for destructive actions
                : Colors.black,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive
                  ? Color.fromARGB(
                      255, 178, 12, 0) // Red color for destructive actions
                  : Colors.black,
              fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () => _handleOptionTap(title, context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Divider(
            color: Colors.grey.shade400,
            thickness: 1,
            height: 0,
          ),
        ),
      ],
    );
  }

  void _handleOptionTap(String title, BuildContext context) {
    switch (title) {
      case "Help and Support":
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => HelpSupportPage()));
        break;
      case "FAQs":
        Navigator.push(context, MaterialPageRoute(builder: (_) => FAQPage()));
        break;
      case "Terms and Condition":
        Navigator.push(context, MaterialPageRoute(builder: (_) => TermsPage()));
        break;
      case "Privacy Policy":
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
        break;
      case "About us":
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => AboutUsPage()));
        break;
      case "Update Preferences":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserInfoPage(isFromSettings: true)),
        );
        break;
      case "Logout":
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
