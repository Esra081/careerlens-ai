import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'bento_card.dart';
import '../services/localization_service.dart';

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
          Text(context.loc('detected_skills'), style: AppTheme.titleStyle.copyWith(fontSize: 18, color: Theme.of(context).textTheme.titleLarge?.color)),
          const SizedBox(height: 20),

          if (skills.isEmpty)
            Text(context.loc('no_skills_found'), style: AppTheme.descriptionStyle.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color))
          else
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: skills.map((skill) {
                return Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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