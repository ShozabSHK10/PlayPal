import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
//screens
import 'package:playpal/features/settings/setting_page.dart';
import 'package:playpal/features/users/user_profile.dart';
import 'package:playpal/features/chats/group_chat.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  DateTime _selectedDay = DateTime.now();
  final user = FirebaseAuth.instance.currentUser;

  String? _currentAddress;
  String? _username;

  @override
  void initState() {
    super.initState();

    if (user != null && !user!.emailVerified) {
      FirebaseAuth.instance.signOut();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return;
    }

    _loadSavedLocation();
  }

  void _navigateToMyBookings() => Navigator.pushNamed(context, '/myBookings');

  Future<void> _loadSavedLocation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final loc = data?['location'];
        final String city = loc?['city'] ?? '';
        final String country = loc?['country'] ?? '';

        setState(() {
          _username = data?['username'] ?? 'User';
          _currentAddress = "$country | $city";
        });
      }
    } catch (e) {
      print("Failed to load saved location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeContent(),
      ChatsPage(),
      Container(),
      ProfilePage(),
      SettingsPage(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _selectedIndex == 0
          ? PreferredSize(
              preferredSize: Size.fromHeight(65),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                                context, '/selectLocation');
                            if (result != null && result is Map) {
                              setState(() {
                                _currentAddress =
                                    "${result['country']} | ${result['city']}";
                              });
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user?.uid)
                                  .update({
                                'location': {
                                  'city': result['city'],
                                  'country': result['country'],
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }
                              });
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/photo/location.png',
                                height: 30,
                                width: 30,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 6),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text("Location",
                                          style: TextStyle(fontSize: 13)),
                                      Icon(Icons.keyboard_arrow_down,
                                          size: 16, color: Colors.black),
                                    ],
                                  ),
                                  Text(
                                    _currentAddress ?? "Set location",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.2),
                          color: Color.fromARGB(255, 255, 166, 1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: TextButton(
                          onPressed: _navigateToMyBookings,
                          style: TextButton.styleFrom(
                            minimumSize: Size(0, 0),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "My Bookings",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_outlined,
                                size: 14,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: _pages[_selectedIndex],
      floatingActionButton: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: _selectedIndex == 0
            ? SizedBox(
                key: ValueKey('fab'),
                height: 60,
                width: 60,
                child: FloatingActionButton(
                  onPressed: () => Navigator.pushNamed(context, '/createMatch'),
                  backgroundColor: const Color.fromARGB(255, 255, 166, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 30),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
      floatingActionButtonLocation: _selectedIndex == 0
          ? FloatingActionButtonLocation.centerDocked
          : null,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        elevation: 6,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (_selectedIndex == 0) ...[
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 0),
                  child: Image.asset(
                    'assets/photo/home.png',
                    height: 24,
                    width: 24,
                    color: _selectedIndex == 0 ? Colors.black : Colors.grey,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Image.asset(
                    'assets/photo/chat.png',
                    height: 24,
                    width: 24,
                    color: _selectedIndex == 1 ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(width: 48), // Space for FAB
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 3),
                  child: Image.asset(
                    'assets/photo/user.png',
                    height: 22,
                    width: 22,
                    color: _selectedIndex == 3 ? Colors.black : Colors.grey,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: Image.asset(
                    'assets/photo/setting.png',
                    height: 24,
                    width: 24,
                    color: _selectedIndex == 4 ? Colors.black : Colors.grey,
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 0),
                  child: Image.asset(
                    'assets/photo/home.png',
                    height: 24,
                    width: 24,
                    color: _selectedIndex == 0 ? Colors.black : Colors.grey,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Image.asset(
                    'assets/photo/chat.png',
                    height: 24,
                    width: 24,
                    color: _selectedIndex == 1 ? Colors.black : Colors.grey,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 3),
                  child: Image.asset(
                    'assets/photo/user.png',
                    height: 22,
                    width: 22,
                    color: _selectedIndex == 3 ? Colors.black : Colors.grey,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: Image.asset(
                    'assets/photo/setting.png',
                    height: 24,
                    width: 24,
                    color: _selectedIndex == 4 ? Colors.black : Colors.grey,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, ${_username ?? 'User'}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Let's explore what's happening around",
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/announcements');
                    },
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: Image.asset(
                        'assets/photo/megaphone.png',
                        height: 28,
                        width: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(child: _buildCalendarBar()),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _isToday(_selectedDay) ? "Today's Events" : "Future Events",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildMatchList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  Widget _buildCalendarBar() {
    final today = DateTime.now();
    final days = List.generate(7, (index) => today.add(Duration(days: index)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: days.map((day) {
          final isSelected = day.day == _selectedDay.day &&
              day.month == _selectedDay.month &&
              day.year == _selectedDay.year;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color.fromARGB(255, 255, 166, 1)
                    : Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black,
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Text(DateFormat('MMM').format(day).toUpperCase(),
                      style: TextStyle(fontSize: 12)),
                  Text("${day.day}",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(DateFormat('EEE').format(day).toUpperCase(),
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMatchList() {
    final startOfDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'pending-payment')
          .where('matchDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('matchDateTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('matchDateTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Something went wrong. Please try again later.",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final allMatches = snapshot.data?.docs ?? [];
        final now = DateTime.now();

        final hasJoinedMatchToday = allMatches.any((doc) {
          final match = doc.data() as Map<String, dynamic>;
          final matchTime = (match['matchDateTime'] as Timestamp).toDate();
          final members = List<String>.from(match['members'] ?? []);
          return matchTime.year == _selectedDay.year &&
              matchTime.month == _selectedDay.month &&
              matchTime.day == _selectedDay.day &&
              members.contains(user?.uid);
        });

        if (hasJoinedMatchToday) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "You've already joined a match for this day.",
              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
          );
        }

        final matches = allMatches.where((doc) {
          final match = doc.data() as Map<String, dynamic>;
          final matchTime = (match['matchDateTime'] as Timestamp).toDate();
          final playersText = match['players'] ?? "6v6";
          final members = List<String>.from(match['members'] ?? []);
          final maxPlayers = playersText == "6v6"
              ? 12
              : playersText == "7v7"
                  ? 14
                  : 16;

          final isPast = matchTime.isBefore(now);
          final isFull = members.length >= maxPlayers;
          final isJoined = members.contains(user?.uid);

          return !isPast && !isFull && !isJoined;
        }).toList();

        if (matches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "No matches scheduled for this day.",
              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
          );
        }

        return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = matches[index];
                final match = doc.data() as Map<String, dynamic>;

                final matchTitle = match['matchTitle'] ?? "Match";
                final matchFees =
                    int.tryParse(match['matchFees'].toString()) ?? 0;
                final location = match['matchLocation'] ?? "Unknown";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 1.2),
                  ),
                  color: Colors.white,
                  elevation: 3,
                  child: SizedBox(
                    height: 140, // 💡 Fixed height here
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween, // Space evenly
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Match Title
                          Text(
                            matchTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),

                          // Match Info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text("$location",
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 14)),
                              Text("Rs $matchFees",
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 14)),
                            ],
                          ),

                          // View Details Button
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/matchDetails',
                                  arguments: doc.id,
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerRight,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "View Details",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(
                                      width:
                                          4), // Reduced spacing between text and icon
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ));
      },
    );
  }
}
