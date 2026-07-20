import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'bento_card.dart';

class AtsScoreCard extends StatelessWidget {
  final Map<String, dynamic> cvData;

  const AtsScoreCard({super.key, required this.cvData});

  @override
  Widget build(BuildContext context) {
    // Backend'den gelen skoru alıyoruz
    int score = 0;
    var rawScore = cvData['ats_score'];

    if (rawScore is int) {
      score = rawScore; // Eğer zaten sayıysa direkt al
    } else if (rawScore is Map) {
      // Eğer backend bir sözlük gönderdiyse, içindeki 'score' anahtarını al
      score = rawScore['total_score'] ?? 0;
    } else if (rawScore != null) {
      // Eğer metin falan gelirse zorla sayıya çevir
      score = int.tryParse(rawScore.toString()) ?? 0;
    }

    return BentoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("ATS Uyumluluk", style: AppTheme.titleStyle.copyWith(fontSize: 18)),
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
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900, // Çok kalın yazı tipi
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            score >= 80 ? "Harika! CV'niz çok güçlü." : "CV'nizi biraz daha geliştirmelisiniz.",
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}