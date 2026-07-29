import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/theme/app_theme.dart';
import '../services/localization_service.dart';

import '../services/api_service.dart';
import '../services/cv_storage_service.dart';
import '../services/match_helper.dart';

class CareerCoachCard extends StatefulWidget {
  final Map<String, dynamic> cvData;

  const CareerCoachCard({super.key, required this.cvData});

  @override
  State<CareerCoachCard> createState() => _CareerCoachCardState();
}

class _CareerCoachCardState extends State<CareerCoachCard> {
  bool _isRefreshing = false;

  Future<void> _refreshAnalysis() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final matched = widget.cvData['matched_skills'] ?? [];
      final missing = widget.cvData['missing_skills'] ?? [];
      final atsScore = MatchHelper.resolveAtsScore(widget.cvData, widget.cvData['job_matches'] ?? []);
      
      String? newAdvice = await ApiService.getCoachAdvice(
        "Software Engineer", 
        List<String>.from(matched), 
        List<String>.from(missing), 
        atsScore
      );

      if (newAdvice != null && mounted) {
        final updatedData = Map<String, dynamic>.from(widget.cvData);
        updatedData['ai_analysis'] = newAdvice;
        await cvStorageService.updateCvData(updatedData, notify: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _generateRealisticAnalysis(Map<String, dynamic> cvData) {
    int atsScore = MatchHelper.resolveAtsScore(cvData, cvData['job_matches'] ?? []);
    List<String> skills = [];
    if (cvData['parsed_skills'] != null) {
      skills = List<String>.from(cvData['parsed_skills']);
    }
    
    String chanceText = atsScore >= 80 ? 'Yüksek' : (atsScore >= 50 ? 'Riskli' : 'Düşük');
    
    String skill1 = skills.isNotEmpty ? skills[0] : 'Yazılım';
    String skill2 = skills.length > 1 ? skills[1] : 'Teknoloji';
    String skill3 = skills.length > 2 ? skills[2] : 'Sistem Mimarisi';
    
    String stackAnalysis = skills.length > 2 
      ? "CV'nizde **$skill1** ve **$skill2** gibi güçlü yetkinlikler var. Ancak modern pazar sadece bu araçları bilmenizi değil, mimariyi anlamanızı bekler."
      : "Mevcut yığın (stack) oldukça zayıf duruyor. Temel teknolojilerde derinleşmeniz gerekiyor.";

    return """### 📊 Gerçekçi Uyum Analizi
ATS skorunuz **%$atsScore**. Bu skorla ilk elemeyi geçme şansınız **$chanceText**.

### 💡 Teknik Derinlik
$stackAnalysis

### 🚀 Acil Aksiyon Planı
Yarın sabah ilk iş olarak **$skill3** üzerine odaklanıp GitHub'a end-to-end bir proje yüklemelisiniz.""";
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> adviceData = widget.cvData['career_advice'] ?? {};
    String displayText = "";
    dynamic rawAnalysis = widget.cvData['ai_analysis'] ?? widget.cvData['summary'];

    if (rawAnalysis != null) {
      String rawString = rawAnalysis.toString().trim();
      if (rawString.startsWith('{')) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(rawString);
          displayText = (decoded['summary'] ?? decoded['ai_analysis'] ?? rawString).toString();
        } catch (_) {
          displayText = rawString;
        }
      } else {
        displayText = rawString;
      }
    }

    if (displayText.isEmpty || 
        displayText.toLowerCase().contains("kullanılamıyor") || 
        displayText.toLowerCase().contains("hata") || 
        displayText.toLowerCase().contains("error")) {
      displayText = _generateRealisticAnalysis(widget.cvData);
    }

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
                  context.loc('ai_coach_analysis_title'),
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
          // Garantili metin basımı ve taşma koruması
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: displayText,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                  h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  h3: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          if (rawAnalysis == null) ...[
             const SizedBox(height: 16),
             Center(
               child: TextButton.icon(
                 onPressed: _isRefreshing ? null : _refreshAnalysis,
                 icon: _isRefreshing 
                     ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                     : const Icon(Icons.refresh, color: Colors.white),
                 label: Text(
                   _isRefreshing ? "Yenileniyor..." : "Analizi Yeniden Getir",
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 ),
                 style: TextButton.styleFrom(
                   backgroundColor: Colors.white.withValues(alpha: 0.2),
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
               ),
             ),
          ],

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
                  Text(
                    context.loc('recommended_path'),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
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