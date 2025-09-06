import 'package:flutter/material.dart';
import 'preferences_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectLevelPage extends StatefulWidget {
  final bool isFromSettings;
  const SelectLevelPage({this.isFromSettings = false});

  @override
  _SelectLevelPageState createState() => _SelectLevelPageState();
}

class _SelectLevelPageState extends State<SelectLevelPage> {
  double _level = 0.0;
  bool _loading = true;
  final ScrollController _levelScrollController = ScrollController();

  final Map<int, String> levelDescriptions = {
    0: "Just starting out, no understanding of football, Curious to explore.",
    1: "Beginning to learn the basics like passing and dribbling, Needs practice.",
    2: "Understands core rules, can play casually but lacks consistency and control.",
    3: "Can participate in casual games and contribute, but still learning positioning.",
    4: "Knows basic strategies, has decent ball control, and can play regularly.",
    5: "Good understanding of teamwork, and can take part in structured matches.",
    6: "Plays regularly with confidence, Shows tactical awareness and technical skill.",
    7: "Highly skilled, near-semi-professional, sets pace, and mentors others.",
  };

  String _getLevelText(double value) {
    if (value <= 2) {
      return 'Beginner';
    } else if (value <= 5) {
      return 'Amateur';
    } else {
      return 'Decent';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserLevel();
  }

  Future<void> _loadUserLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['levelValue'] != null) {
        setState(() {
          _level = (data['levelValue'] as num).toDouble();
        });
      }
    }

    setState(() {
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _levelScrollController.jumpTo((_level * 102)
          .clamp(0, _levelScrollController.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    int levelInt = _level.round().clamp(0, 7);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Select Your Level",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/photo/football.png',
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(width: 10),
                      Text('Football',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      controller: _levelScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      itemBuilder: (context, index) {
                        final isSelected = levelInt == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          constraints: const BoxConstraints(minWidth: 20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 255, 166, 1)
                                : Colors.white,
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              "$index",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(
                      levelDescriptions[levelInt] ?? "Select your level",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 500,
                      child: Slider(
                        value: _level,
                        min: 0,
                        max: 7,
                        divisions: 7,
                        onChanged: (value) {
                          setState(() {
                            _level = value;
                          });
                        },
                        activeColor: Color.fromARGB(255, 255, 166, 1),
                        inactiveColor: Color.fromARGB(255, 63, 46, 1),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      backgroundColor: Colors.black,
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                          'levelValue': _level,
                          'levelText': _getLevelText(_level),
                        }, SetOptions(merge: true));

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreferencesPage(
                                isFromSettings: widget.isFromSettings),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Color.fromARGB(255, 255, 166, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
