import 'package:flutter/material.dart';

class AppColors {
  // Teal (Admin primary)
  static const Color primary = Color(0xFF0F6E56);
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color primaryMid = Color(0xFF1D9E75);
  static const Color primaryDark = Color(0xFF085041);
  static const Color primaryText = Color(0xFF04342C);

  // Blue (Doctor primary)
  static const Color bluePrimary = Color(0xFF185FA5);
  static const Color blueLight = Color(0xFFE6F1FB);
  static const Color blueMid = Color(0xFF378ADD);
  static const Color blueDark = Color(0xFF0C447C);
  static const Color blueText = Color(0xFF042C53);

  // Red
  static const Color redPrimary = Color(0xFFA32D2D);
  static const Color redLight = Color(0xFFFCEBEB);
  static const Color redMid = Color(0xFFE24B4A);
  static const Color redText = Color(0xFF501313);

  // Amber
  static const Color amberPrimary = Color(0xFF854F0B);
  static const Color amberLight = Color(0xFFFAEEDA);
  static const Color amberMid = Color(0xFFBA7517);
  static const Color amberText = Color(0xFF412402);

  // Gray
  static const Color grayPrimary = Color(0xFF5F5E5A);
  static const Color grayLight = Color(0xFFF1EFE8);
  static const Color grayMid = Color(0xFF888780);
  static const Color grayText = Color(0xFF2C2C2A);

  // Background
  static const Color background = Color(0xFFF4F6FB);
  static const Color cardBackground = Colors.white;
  static const Color border = Color(0xFFF0F0F0);
  static const Color borderMid = Color(0xFFE5E7EB);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Legacy aliases kept for compatibility
  static const Color success = primaryMid;
  static const Color error = redMid;
  static const Color warning = amberMid;
  static const Color sidebarBg = primaryDark;
  static const Color sidebarText = primaryLight;
  static const Color sidebarActive = primary;
  static const Color primaryLightAlias = primaryLight;
}

class AppStrings {
  static const String appName = 'MediChain';

  static const List<String> departments = [
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Gynecology',
    'Dentistry',
    'General',
  ];

  static const List<String> slotDurations = [
    '15 min',
    '20 min',
    '30 min',
    '45 min',
    '60 min',
  ];

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