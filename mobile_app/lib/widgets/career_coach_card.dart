import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CareerCoachCard extends StatelessWidget {
  final Map<String, dynamic> cvData;

  const CareerCoachCard({super.key, required this.cvData});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> adviceData = cvData['career_advice'] ?? {};
    String targetRole = adviceData['target_role'] ?? 'Kariyeriniz';
    String summary = adviceData['summary'] ?? 'Analiz yapılamadı.';
    List<dynamic> learningPath = adviceData['learning_path'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32), // Geniş, ferah boşluk
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentGradientStart, AppTheme.accentGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25), // Kendi renginde parlayan gölge
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), // Cam (Glass) efekti
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "AI Koç: $targetRole",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),

          if (learningPath.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1), // Hafif koyulaştırılmış alan
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tavsiye Edilen Rota",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ...learningPath.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          item['skill'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}