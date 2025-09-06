import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _countryController = TextEditingController();

  File? _profileImage;
  String? _uploadedImageUrl;
  double _uploadProgress = 0;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection("users").doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _usernameController.text = data["username"] ?? "";
        _fullNameController.text = data["fullName"] ?? "";
        _emailController.text = _auth.currentUser?.email ?? "user@example.com";
        _heightController.text = data["height"] ?? "";
        _countryController.text = data["country"] ?? "";
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection("users").doc(uid).get();
    final data = doc.data();
    if (data != null && data.containsKey("profileImage")) {
      setState(() {
        _uploadedImageUrl = data["profileImage"];
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadProfileImage(String uid) async {
    if (_profileImage == null) return;

    try {
      final imageBytes = await _profileImage!.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception("Invalid image");

      // Resize + compress for performance
      final resized = img.copyResize(originalImage, width: 300);
      final compressedBytes = img.encodeJpg(resized, quality: 70);

      // Always save as profile.jpg in the user's folder
      final ref = _storage.ref().child('profile_images/$uid/profile.jpg');
      print("Uploading to: ${ref.fullPath}");

      final uploadTask = ref.putData(Uint8List.fromList(compressedBytes));

      uploadTask.snapshotEvents.listen((snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await uploadTask.timeout(Duration(seconds: 20));

      if (snapshot.state == TaskState.success) {
        _uploadedImageUrl = await ref.getDownloadURL();
        print("Upload complete: $_uploadedImageUrl");
      } else {
        throw Exception("Upload failed. Task state: ${snapshot.state}");
      }
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _uploadProgress = 0;
    });

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = "User is not logged in.";
      });
      return;
    }

    try {
      if (_profileImage != null) {
        await _uploadProfileImage(uid);
      }

      // Update Firestore with profile details + image URL
      await _firestore.collection('users').doc(uid).set({
        "username": _usernameController.text.trim(),
        "fullName": _fullNameController.text.trim(),
        "height": _heightController.text.trim(),
        "country": _countryController.text.trim(),
        if (_uploadedImageUrl != null) "profileImage": _uploadedImageUrl,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated")),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildUpdateSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          _isSaving
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text("Update Profile",
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "  Profile Editor",
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
      body: SafeArea(
        child: Column(
          children: [
            if (_uploadProgress > 0 && _uploadProgress < 1)
              LinearProgressIndicator(value: _uploadProgress),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_uploadedImageUrl != null
                                  ? NetworkImage(_uploadedImageUrl!)
                                  : null),
                          backgroundColor: Colors.grey[300],
                          child:
                              _profileImage == null && _uploadedImageUrl == null
                                  ? Icon(Icons.person,
                                      size: 50, color: Colors.white)
                                  : null,
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildField("Username", _usernameController),
                    _buildField("Email", _emailController, enabled: false),
                    _buildField("Full Name", _fullNameController),
                    _buildField("Height", _heightController),
                    _buildField("Country", _countryController),
                  ],
                ),
              ),
            ),
            _buildUpdateSection(),
          ],
        ),
      ),
    );
  }
}
