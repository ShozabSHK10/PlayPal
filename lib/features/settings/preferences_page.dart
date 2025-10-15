import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/features/home/home_page.dart';

class PreferencesPage extends StatefulWidget {
  final bool isFromSettings;
  const PreferencesPage({this.isFromSettings = false});

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  List<bool> _selectedDays = List.generate(7, (index) => false);
  int _selectedTime = 0;
  bool _loading = true;

  final List<String> timeSlots = [
    "All Day 00:00-23:59",
    "Morning 06:00-12:00",
    "Afternoon 12:00-18:00",
    "Evening 18:00-24:00",
    "Early Evening 17:00-20:00",
    "Late Evening 20:00-00:00"
  ];

  final List<String> dayMap = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        // Load preferred days
        if (data['preferredDays'] != null) {
          List<String> savedDays = List<String>.from(data['preferredDays']);
          for (int i = 0; i < dayMap.length; i++) {
            _selectedDays[i] = savedDays.contains(dayMap[i]);
          }
        }

        // Load preferred time slot
        if (data['preferredTimeSlot'] != null) {
          int savedIndex = timeSlots.indexOf(data['preferredTimeSlot']);
          if (savedIndex != -1) {
            _selectedTime = savedIndex;
          }
        }
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Add Your Preferences",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Day',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .asMap()
                        .entries
                        .map((entry) {
                      int index = entry.key;
                      String day = entry.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDays[index] = !_selectedDays[index];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.black, width: 1), // Black outline
                          ),
                          child: CircleAvatar(
                            backgroundColor: _selectedDays[index]
                                ? Color.fromARGB(255, 255, 166, 1)
                                : Colors.blueGrey.shade200,
                            child: Text(
                              day,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text('Select Time',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 10),
                  Column(
                    children: timeSlots.asMap().entries.map((entry) {
                      int index = entry.key;
                      String time = entry.value;

                      final isSelected = _selectedTime == index;

                      return ListTile(
                        leading: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.5),
                            color: isSelected
                                ? Color.fromARGB(255, 255, 166, 1)
                                : Colors.transparent,
                          ),
                        ),
                        title: Text(
                          time,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTime = index;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      backgroundColor: Colors.black,
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        List<String> selectedDays = [];
                        for (int i = 0; i < _selectedDays.length; i++) {
                          if (_selectedDays[i]) {
                            selectedDays.add(dayMap[i]);
                          }
                        }

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                          'preferredDays': selectedDays,
                          'preferredTimeSlot': timeSlots[_selectedTime],
                          'onboardingCompleted': true,
                        }, SetOptions(merge: true));

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => HomePage()),
                          (route) => false,
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
