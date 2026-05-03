import 'package:flutter/material.dart';

class AppColors {
  // App Colors
  static const Color primary = Colors.blue;
  static const Color primaryLight = Color(0xFFBBDEFB);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;

  // Sidebar Colors
  static const Color sidebarBg = Color(0xFF1565C0);
  static const Color sidebarText = Color(0xFFBBDEFB);
  static const Color sidebarActive = Color(0xFF1976D2);

  // Status Colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Border Color
  static const Color border = Color(0xFFE0E0E0);
}

class AppStrings {
  // App Name
  static const String appName = 'Healthcare Admin';

  // Doctor Department List
  static const List<String> departments = [
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Gynecology',
    'Dentistry',
    'General',
  ];

  // Appointment Slot Duration Options
  static const List<String> slotDurations = [
    '15 min',
    '20 min',
    '30 min',
    '45 min',
    '60 min',
  ];

  // Week Days
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
