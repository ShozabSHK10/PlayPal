import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  bool _isPasswordVisible = false; // Track password visibility

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55, // Set fixed height to match previous style
      width: 355, // Adjust width as needed
      padding: const EdgeInsets.symmetric(horizontal: 10), // Ensure spacing
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscureText
            ? !_isPasswordVisible
            : false, // Toggle for passwords
        decoration: InputDecoration(
          hintText: widget.hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Match previous design
              borderSide: BorderSide(width: 2)),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 15, horizontal: 20), // Adjust padding
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null, // Only show eye icon for passwords
        ),
      ),
    );
  }
}
