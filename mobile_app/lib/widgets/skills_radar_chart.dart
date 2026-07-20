import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'bento_card.dart';

class SkillsRadarChart extends StatelessWidget {
  final Map<String, dynamic> cvData;

  const SkillsRadarChart({super.key, required this.cvData});

  @override
  Widget build(BuildContext context) {
    List<String> skills = [];
    if (cvData['parsed_skills'] != null) {
      skills = List<String>.from(cvData['parsed_skills']);
    }

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tespit Edilen Yetkinlikler", style: AppTheme.titleStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 20),

          if (skills.isEmpty)
            const Text("CV'nizde teknoloji bulunamadı.", style: AppTheme.descriptionStyle)
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 12.0,
              children: skills.map((skill) {
                return Chip(
                  label: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor, // Yazı koyu mor
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08), // Arka plan uçuk mor
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Modern köşe
                  ),
                  side: BorderSide.none, // Kenarlıkları tamamen kaldırdık
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}