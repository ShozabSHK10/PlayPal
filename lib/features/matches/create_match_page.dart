// CreateMatchPage UI refactored for clean layout
// Icons and animations not included per user instruction

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CreateMatchPage extends StatefulWidget {
  @override
  _CreateMatchPageState createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final TextEditingController _matchFeesController = TextEditingController();
  final TextEditingController _matchTitleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  String? _selectedPlayers;
  String? _selectedLocation;
  String? _selectedDuration;
  File? _paymentImage;
  bool _isSubmitting = false;

  String? _titleError,
      _locationError,
      _dateError,
      _timeError,
      _playerError,
      _durationError,
      _imageError;

  final picker = ImagePicker();

  final List<String> _playerOptions = ["6v6", "7v7", "8v8"];
  final List<String> _locationOptions = [
    "Diamond City Ground",
    "Starla Complex"
  ];
  final List<String> _durationOptions = ["1:30", "2:00", "2:30", "3:00"];

  Duration _parseDuration(String value) {
    final parts = value.split(":");
    return Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1]));
  }

  DateTime? _combineDateAndTime() {
    if (_selectedDate == null || _selectedStartTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );
  }

  List<String> _getAvailablePlayerOptions() {
    return _selectedLocation == "Starla Complex"
        ? ["6v6", "7v7"]
        : _playerOptions;
  }

  void _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(Duration(days: 2)),
      firstDate: now.add(Duration(days: 2)),
      lastDate: now.add(Duration(days: 7)),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _pickStartTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.copyWith(
                  // 🛠️ Aligns the colon in the middle
                  headlineMedium: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
            timePickerTheme: TimePickerThemeData(
              dialHandColor: Colors.black,
              dialTextColor:
                  WidgetStateColor.resolveWith((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black;
              }),
              dayPeriodColor: Color.fromARGB(255, 255, 166, 1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final totalMinutes = pickedTime.hour * 60 + pickedTime.minute;
      if (totalMinutes < 360 || totalMinutes > 1350) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Start time must be between 6:00 AM and 10:30 PM"),
          ),
        );
        return;
      }
      setState(() {
        _selectedStartTime = pickedTime;
        _updateFees();
      });
    }
  }

  void _updateFees() {
    if (_selectedLocation != null &&
        _selectedStartTime != null &&
        _selectedDuration != null) {
      final startMinutes =
          _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
      final isDay = startMinutes >= 360 && startMinutes < 1020;
      final feeMapDay = {
        "1:30": "2750",
        "2:00": "3750",
        "2:30": "4750",
        "3:00": "5500"
      };
      final feeMapEvening = {
        "1:30": "3800",
        "2:00": "5000",
        "2:30": "6300",
        "3:00": "7000"
      };
      _matchFeesController.text = isDay
          ? (feeMapDay[_selectedDuration!] ?? "")
          : (feeMapEvening[_selectedDuration!] ?? "");
    }
  }

  Future<void> _pickPaymentImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final extension = picked.name.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'png') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Only .jpg or .png images are allowed")),
        );
        return;
      }
      setState(() => _paymentImage = file);
    }
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _showError(String? error) => error == null
      ? SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(error, style: TextStyle(color: Colors.red, fontSize: 12)),
        );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontWeight: FontWeight.w400, // Regular weight
          color: Colors.grey.shade500, // Softer grey
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      );

  Widget _dropdown(
      List<String> options, String? value, Function(String?) onChanged,
      {String? suffix}) {
    return DropdownButtonFormField(
      value: value,
      items: options
          .map((e) => DropdownMenuItem(
              value: e, child: Text(suffix != null ? "$e$suffix" : e)))
          .toList(),
      onChanged: onChanged,
      decoration: _inputDecoration("Select"),
    );
  }

  Widget _tappableText(String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text("Create Match",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader("Match Info"),
                        TextField(
                          controller: _matchTitleController,
                          decoration: _inputDecoration("Enter Match Title"),
                          textAlign: TextAlign.center,
                        ),
                        _showError(_titleError),
                        const SizedBox(height: 20),
                        _dropdown(_locationOptions, _selectedLocation, (val) {
                          setState(() {
                            _selectedLocation = val;
                            _selectedPlayers = null;
                            _updateFees();
                          });
                        }),
                        _showError(_locationError),
                        _sectionHeader("Date & Time"),
                        Row(children: [
                          Expanded(
                            child: Column(children: [
                              _tappableText(
                                  _selectedDate == null
                                      ? "Select Date"
                                      : DateFormat('EEE, MMM d')
                                          .format(_selectedDate!),
                                  () => _pickDate(context)),
                              _showError(_dateError)
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(children: [
                              _tappableText(
                                  _selectedStartTime == null
                                      ? "Select Time"
                                      : _selectedStartTime!.format(context),
                                  () => _pickStartTime(context)),
                              _showError(_timeError)
                            ]),
                          ),
                        ]),
                        _sectionHeader("Format & Duration"),
                        Row(children: [
                          Expanded(
                            child: Column(children: [
                              _dropdown(_durationOptions, _selectedDuration,
                                  (val) {
                                setState(() {
                                  _selectedDuration = val;
                                  _updateFees();
                                });
                              }, suffix: " hrs"),
                              _showError(_durationError)
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(children: [
                              IgnorePointer(
                                ignoring: _selectedLocation == null,
                                child: Opacity(
                                  opacity: _selectedLocation == null ? 0.5 : 1,
                                  child: _dropdown(
                                    _getAvailablePlayerOptions(),
                                    _selectedPlayers,
                                    (val) =>
                                        setState(() => _selectedPlayers = val),
                                  ),
                                ),
                              ),
                              _showError(_playerError)
                            ]),
                          ),
                        ]),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Payment",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  final matchFee = int.tryParse(
                                          _matchFeesController.text.trim()) ??
                                      0;
                                  final playersText = _selectedPlayers ?? "";
                                  final perSide = int.tryParse(
                                          playersText.split('v').first) ??
                                      0;

                                  final totalPlayers = perSide * 2;

                                  int userShare = 0;
                                  if (matchFee > 0 && totalPlayers > 0) {
                                    final rawShare = matchFee / totalPlayers;
                                    userShare = ((rawShare + 9) ~/ 10) *
                                        10; // Round up to nearest 10
                                  }

                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                      side: BorderSide(
                                          color: Colors.black, width: 1.5),
                                    ),
                                    backgroundColor: Colors
                                        .transparent, // Ensures ClipRRect background works
                                    builder: (context) {
                                      return ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                        child: Container(
                                          color: const Color.fromARGB(
                                              255, 223, 218, 218),
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 16, 16, 10),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: Text(
                                                  "Payment Accounts",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(height: 12),

                                              // JazzCash
                                              const Text(
                                                "JazzCash",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      "Ahmed Saeed: 0308-6104146",
                                                      style: TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.copy,
                                                        size: 18),
                                                    tooltip: "Copy",
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                          const ClipboardData(
                                                              text:
                                                                  "Ahmed Saeed: 0308-6104146"));
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                "JazzCash details copied")),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),

                                              // Meezan Bank
                                              const Text(
                                                "Meezan Bank",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      "Shozab Sohail: 4148-0107790161",
                                                      style: TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.copy,
                                                        size: 18),
                                                    tooltip: "Copy",
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                          const ClipboardData(
                                                              text:
                                                                  "Shozab Sohail: 4148-0107790161"));
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                "Meezan Bank details copied")),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 14),
                                              Text(
                                                "Amount to be paid: Rs $userShare",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: const Text(
                                  "Click to pay",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 3, 96, 122),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_paymentImage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.black12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.file(
                                  _paymentImage!,
                                  fit: BoxFit.cover,
                                  height: 160,
                                  width: double.infinity,
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickPaymentImage,
                                icon: const Icon(
                                  Icons.upload,
                                  color: Color.fromARGB(255, 3, 96, 122),
                                ),
                                label: const Text(
                                  "Upload Screenshot",
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        _showError(_imageError),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom button — always visible
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _createMatch,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isSubmitting ? "Creating..." : "Confirm Match Creation",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 166, 1),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 1.3),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _createMatch() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    setState(() {
      _titleError = null;
      _locationError = null;
      _dateError = null;
      _timeError = null;
      _playerError = null;
      _durationError = null;
      _imageError = null;
    });

    final title = _matchTitleController.text.trim();
    final titleWords = title.split(RegExp(r'\s+'));

    bool hasError = false;

    if (title.isEmpty) {
      _titleError = "Title cannot be empty";
      hasError = true;
    } else if (titleWords.length > 20) {
      _titleError = "Title must be 20 words or fewer";
      hasError = true;
    }
    if (_selectedLocation == null) {
      _locationError = "Please select a ground";
      hasError = true;
    }
    if (_selectedDate == null) {
      _dateError = "Please select a match date";
      hasError = true;
    }
    if (_selectedStartTime == null) {
      _timeError = "Please select a start time";
      hasError = true;
    }
    if (_selectedPlayers == null) {
      _playerError = "Please select a player format";
      hasError = true;
    }
    if (_selectedDuration == null) {
      _durationError = "Please select a duration";
      hasError = true;
    }
    if (_paymentImage == null) {
      _imageError = "Upload payment screenshot";
      hasError = true;
    }

    if (hasError) {
      setState(() => _isSubmitting = false);
      return;
    }

    final startDateTime = _combineDateAndTime();
    final duration = _parseDuration(_selectedDuration!);
    final endDateTime = startDateTime!.add(duration);
    if (endDateTime.hour >= 24) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Match must end before midnight")));
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final matchRef = FirebaseFirestore.instance.collection("matches").doc();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("match_screenshots/${matchRef.id}/${user.uid}/screenshot.jpg");

      await storageRef.putFile(_paymentImage!);
      final paymentUrl = await storageRef.getDownloadURL();

      await matchRef.set({
        "matchTitle": title,
        "matchLocation": _selectedLocation,
        "matchDateTime": startDateTime,
        "matchDuration": _selectedDuration,
        "players": _selectedPlayers,
        "matchFees": _matchFeesController.text.trim(),
        "members": [user.uid],
        "creatorId": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "status": "pending-payment",
        "paymentScreenshot": paymentUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Match submitted for confirmation!")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error during match creation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create match")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
