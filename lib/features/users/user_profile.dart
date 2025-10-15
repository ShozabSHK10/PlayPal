import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/features/settings/achievements_page.dart';
import 'package:playpal/features/settings/active_level_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String fullName = "User";
  String username = "";
  String dob = "NA";
  String country = "NA";
  String gender = "NA";
  String level = "5.5";
  String height = "NA";
  String? profileImageUrl;

  String explorerLevel = "Loading...";
  String reliabilityLevel = "Loading...";
  String activeLevelText = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final uid = user!.uid;

      DocumentSnapshot doc =
          await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          fullName = data["fullName"] ?? "User";
          username = data["username"] ?? "";
          dob = data["dob"] ?? "NA";
          country = data["country"] ?? "NA";
          gender = data["gender"] ?? "NA";
          height = data["height"] ?? "NA";
          profileImageUrl = data["profileImage"];
        });
      }

      // Fetch match data
      final now = DateTime.now();
      final past30 = Timestamp.fromDate(now.subtract(Duration(days: 30)));

      final allMatchesSnap = await _firestore
          .collection('matches')
          .where('members', arrayContains: uid)
          .where('status', isEqualTo: 'completed')
          .get();

      final recentMatchesSnap = await _firestore
          .collection('matches')
          .where('members', arrayContains: uid)
          .where('status', isEqualTo: 'completed')
          .where('matchDateTime', isGreaterThanOrEqualTo: past30)
          .get();

      int totalCompleted = allMatchesSnap.docs.length;
      int matchesLast30 = recentMatchesSnap.docs.length;

      // Determine explorer level
      String explorer = "Newbie";
      if (totalCompleted >= 100) {
        explorer = "G.O.A.T";
      } else if (totalCompleted >= 75) {
        explorer = "Game Legend";
      } else if (totalCompleted >= 50) {
        explorer = "Almost Godlike";
      } else if (totalCompleted >= 31) {
        explorer = "Future king";
      } else if (totalCompleted >= 15) {
        explorer = "Invincible";
      } else if (totalCompleted >= 6) {
        explorer = "Veteran";
      } else if (totalCompleted >= 1) {
        explorer = "Explorer";
      }

      // Determine active level
      String activeLevel = "Inactive";
      if (matchesLast30 >= 8) {
        activeLevel = "Unstoppable";
      } else if (matchesLast30 >= 6) {
        activeLevel = "On Fire";
      } else if (matchesLast30 >= 4) {
        activeLevel = "Almost There";
      } else if (matchesLast30 >= 2) {
        activeLevel = "Warming Up";
      } else if (matchesLast30 >= 1) {
        activeLevel = "Getting Started";
      }

      // Determine reliability (fake logic for now — you can enhance this)
      String reliability = "Perfect";
      if (totalCompleted >= 10) {
        reliability = "Perfect";
      } else if (totalCompleted >= 5) {
        reliability = "Consistent";
      } else if (totalCompleted >= 3) {
        reliability = "Decent";
      } else if (totalCompleted >= 1) {
        reliability = "Low";
      } else {
        reliability = "Poor";
      }

      setState(() {
        explorerLevel = explorer;
        activeLevelText = activeLevel;
        reliabilityLevel = reliability;
      });
    }
  }

  Widget _infoLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _navigableCard({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 240, 240, 240),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: AppBar(
            backgroundColor: Color.fromARGB(255, 240, 240, 240),
            elevation: 0,
            foregroundColor: Colors.black,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/discoverPlayers');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/photo/search.png',
                        height: 25,
                        width: 25,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: profileImageUrl == null
                            ? Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfilePage()),
                        );
                        _loadUserData();
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/photo/edit.png',
                          height: 30,
                          width: 30,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLabel("username", username),
                      SizedBox(height: 8),
                      _infoLabel("DOB", dob),
                      SizedBox(height: 8),
                      _infoLabel("Country", country),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoLabel("Level $level", "Higher intermediate"),
                _infoLabel("Height", height),
                _infoLabel("Gender", gender),
              ],
            ),
            SizedBox(height: 30),
            _navigableCard(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AchievementsPage(
                                currentAchievement: explorerLevel),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/photo/achievements.png',
                            height: 40,
                            width: 40,
                          ),
                          SizedBox(width: 10),
                          Text("Achievements - ",
                              style: TextStyle(fontSize: 16)),
                          Text(explorerLevel,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _navigableCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ActiveLevelPage(currentActiveLevel: activeLevelText),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/photo/active_level.png',
                    height: 40,
                    width: 40,
                  ),
                  SizedBox(width: 10),
                  Text("Active Level - ", style: TextStyle(fontSize: 16)),
                  Text(activeLevelText,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
