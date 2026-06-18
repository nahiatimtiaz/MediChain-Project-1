// import 'package:flutter/material.dart';

// class InputField extends StatelessWidget {
//   final String label;
//   final String? hint;
//   final String? errorText;
//   final bool obscureText;
  
//   final TextEditingController? controller; 
//   final TextInputType? keyboardType;       
//   final Widget? icon;                      

//   const InputField({
//     super.key, 
//     required this.label,
//     this.controller,
//     this.keyboardType,
//     this.hint,
//     this.errorText,
//     this.icon,
//     this.obscureText = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         obscureText: obscureText || keyboardType == TextInputType.visiblePassword,
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: hint,
//           errorText: errorText,
//           prefixIcon: icon,
//           border: const OutlineInputBorder(), // Optional: adds a clean border box
//         ),
//       ),
//     );
//   }
// }