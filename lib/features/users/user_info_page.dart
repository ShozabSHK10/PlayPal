import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:playpal/features/settings/level_select_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoPage extends StatefulWidget {
  final bool isFromSettings;
  const UserInfoPage({this.isFromSettings = false});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.isFromSettings) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _usernameController.text = data['username'] ?? '';
        _selectedGender = data['gender'];
        if (data['dob'] != null) {
          _dobController.text = data['dob'];
          _selectedDate = DateTime.tryParse(data['dob']);
        }
        setState(() {});
      }
    }
  }

  void _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': _usernameController.text.trim(),
        'dob': _dobController.text,
        'gender': _selectedGender,
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                SelectLevelPage(isFromSettings: widget.isFromSettings)),
      );
    }
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 240, 240),
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: widget.isFromSettings,
        title: Text(
          widget.isFromSettings ? "Update Profile" : "Tell us more about you",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: widget.isFromSettings
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 22),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputCard(
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: InputBorder.none,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter a username'
                      : null,
                ),
              ),
              _buildInputCard(
                child: TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your date of birth';
                    }
                    if (_selectedDate != null &&
                        DateTime.now().difference(_selectedDate!).inDays / 365 <
                            12) {
                      return 'You must be at least 12 years old';
                    }
                    return null;
                  },
                ),
              ),
              _buildInputCard(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _selectedGender,
                  items: ['Male', 'Female', 'Other'].map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedGender = newValue),
                  validator: (value) =>
                      value == null ? 'Please select a gender' : null,
                ),
              ),
              Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: Colors.black,
                  onPressed: _saveUserInfo,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Color.fromARGB(255, 255, 166, 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
