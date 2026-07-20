import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/bento_card.dart';
import '../widgets/skill_chip.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final String title = job['job_title'] ?? 'Pozisyon';
    final String company = job['company'] ?? 'Şirket';
    final String matchPct = job['match_percentage'] ?? '%0';

    final List<String> matchedSkills = List<String>.from(job['matched_skills'] ?? []);
    final List<String> missingSkills = List<String>.from(job['missing_skills'] ?? []);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        title: const Text("İlan Detayı", style: AppTheme.titleStyle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ŞİRKET VE İLAN BAŞLIĞI KARTI
            BentoCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.backgroundColor,
                    child: Text(
                      company.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: AppTheme.titleStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(company, style: AppTheme.subtitleStyle.copyWith(color: AppTheme.textLightColor)),
                  const SizedBox(height: 24),

                  // Eşleşme Oranı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "CV Eşleşme: $matchPct",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. YETKİNLİK ANALİZİ KARTI
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Yetkinlik Analizi", style: AppTheme.titleStyle.copyWith(fontSize: 18)),
                  const SizedBox(height: 20),

                  const Text("✓ Eşleşen Yetenekler", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: matchedSkills.map((skill) => SkillChip(label: skill)).toList(),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: AppTheme.backgroundColor, thickness: 2),
                  ),

                  const Text("⚠️ Geliştirilmesi Gerekenler", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: missingSkills.map((skill) => SkillChip(label: skill, isMissing: true)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // ALT KISIMDA SABİT BAŞVUR BUTONU
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$company şirketine başvuru sayfasına yönlendiriliyor...")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text("Hemen Başvur", style: AppTheme.buttonTextStyle),
          ),
        ),
      ),
    );
  }
}