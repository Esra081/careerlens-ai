import 'package:flutter/material.dart';

class AppTheme {
  // --- YENİ MODERN RENK PALETİ ---
  static const Color primaryColor = Color(0xFF6B48FF);
  static const Color accentGradientStart = Color(0xFF6B48FF);
  static const Color accentGradientEnd = Color(0xFF48A6FF);

  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white; // <--- EKSİK OLAN SATIR BU
  static const Color textColor = Color(0xFF1A2B47);
  static const Color textLightColor = Color(0xFF718096);

  // --- STİLLER ---
  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textLightColor,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontSize: 15,
    color: textLightColor,
    height: 1.5,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Hata veren stil:
  static const TextStyle actionButtonStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}