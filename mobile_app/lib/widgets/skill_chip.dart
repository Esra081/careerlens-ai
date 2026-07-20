import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final bool isMissing; // Eksik yetenek ise kırmızımsı, eşleşen ise yeşil/mor olacak

  const SkillChip({super.key, required this.label, this.isMissing = false});

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isMissing
        ? Colors.red.withValues(alpha: 0.1)
        : AppTheme.primaryColor.withValues(alpha: 0.1);

    final Color textColor = isMissing
        ? Colors.red.shade700
        : AppTheme.primaryColor;

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
    );
  }
}