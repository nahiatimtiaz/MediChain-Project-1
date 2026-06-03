import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  // Corrected types: Objects use their specific Flutter classes instead of String
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  
  final TextEditingController? controller; // Changed from String
  final TextInputType? keyboardType;       // Changed from String
  final Widget? icon;                      // Changed from String (Allows Icon(Icons.abc))

  const InputField({
    super.key, // Updated to modern Flutter key syntax
    required this.label,
    this.controller,
    this.keyboardType,
    this.hint,
    this.errorText,
    this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        // Uses obscureText variable directly, fallback to checking password type
        obscureText: obscureText || keyboardType == TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          prefixIcon: icon,
          border: const OutlineInputBorder(), // Optional: adds a clean border box
        ),
      ),
    );
  }
}