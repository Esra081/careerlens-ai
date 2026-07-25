import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'bento_card.dart';
import '../services/localization_service.dart';
import '../services/match_helper.dart';

class AtsScoreCard extends StatelessWidget {
  final Map<String, dynamic> cvData;

  const AtsScoreCard({super.key, required this.cvData});

  @override
  Widget build(BuildContext context) {
    // Önce job_matches'tan hesapla (fallback dahil)
    final jobMatches = MatchHelper.getJobMatches(cvData);
    final int score = MatchHelper.resolveAtsScore(cvData, jobMatches);

    return BentoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(context.loc('ats_compatibility'), style: AppTheme.titleStyle.copyWith(fontSize: 18, color: Theme.of(context).textTheme.titleLarge?.color)),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.backgroundColor, // Arka planla uyumlu iz
                  color: AppTheme.primaryColor,
                  strokeCap: StrokeCap.round, // Çubuğun uçlarını yuvarlar (Profesyonel dokunuş)
                ),
              ),
              Text(
                "%$score",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900, // Çok kalın yazı tipi
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            score >= 80 ? context.loc('ats_great') : context.loc('ats_improve'),
            style: AppTheme.captionStyle.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}