import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/theme/app_theme.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

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
  String? _overrideAdvice;

  Future<void> _refreshAnalysis() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final jobMatches = widget.cvData['job_matches'] as List<dynamic>? ?? [];
      
      String targetRole = "Yazılım Geliştirici";
      List<String> matched = [];
      List<String> missing = [];
      int atsScore = MatchHelper.resolveAtsScore(widget.cvData, jobMatches);

      if (jobMatches.isNotEmpty) {
        final topJob = jobMatches[0];
        targetRole = (topJob['job_title'] ?? topJob['title'] ?? targetRole).toString();
        matched = List<String>.from(topJob['matched_skills'] ?? topJob['matchedSkills'] ?? []);
        missing = List<String>.from(topJob['missing_skills'] ?? topJob['missingSkills'] ?? []);
      }
      if (matched.isEmpty) {
        matched = List<String>.from(widget.cvData['parsed_skills'] ?? userProvider.skills.take(4).toList());
      }

      String? newAdvice = await ApiService.getCoachAdvice(
        targetRole, 
        matched, 
        missing, 
        atsScore,
        userProvider.skills,
        userProvider.experienceLevel,
        lang: settingsService.languageCode,
      );

      if (newAdvice != null && mounted) {
        setState(() {
          _overrideAdvice = newAdvice;
        });
        final updatedData = Map<String, dynamic>.from(widget.cvData);
        updatedData['ai_analysis'] = newAdvice;
        await cvStorageService.updateCvData(updatedData, notify: true);
      }
    } catch (e) {
      debugPrint("Coach advice refresh error: $e");
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
    
    String skill1 = skills.isNotEmpty ? skills[0] : 'Yazılım Geliştirme';
    String skill2 = skills.length > 1 ? skills[1] : 'Teknik Altyapı';
    String skill3 = skills.length > 2 ? skills[2] : 'Sistem Mimarisi';
    
    String stackAnalysis = skills.length > 2 
      ? "CV'nizde **$skill1** ve **$skill2** gibi güçlü teknik yetkinlikler yer alıyor. Ancak sektör sadece bu araçları bilmenizi değil, mimari tasarımı ve uçtan uca sistem yönetimini kanıtlamanızı bekler."
      : "Mevcut teknik yığın oldukça kısıtlı görünüyor. Temel teknolojilerde derinleşmeniz ve pratik projelerle bunu kanıtlamanız gerekiyor.";

    return """### 1. 📊 Gerçekçi Uyum Analizi
ATS skorunuz **%$atsScore**. Bu skorla ilk teknik elemeyi geçme şansınız **$chanceText**. İlan gereksinimleriyle doğrudan örtüşen kısımlar mevcut olsa da kritik araç ve deneyim boşlukları bulunuyor.

### 2. 🎯 Kapatılması Gereken Açık & Proje Önerisi
$stackAnalysis
Açığı kapatmak için yarın sabah **$skill3** odaklı, REST API entegrasyonu ve Docker konteynerizasyonu içeren uçtan uca bir projeyi GitHub profilinize yüklemelisiniz.

### 3. ✍️ CV İyileştirme (STAR Formatı)
- **Eski Hali:** $skill1 teknolojileriyle projeler geliştirdim.
- **Olması Gereken Hali:** $skill1 kullanarak mikroservis mimarisinde yüksek verimli API servisleri geliştirdim; sistem yanıt sürelerini %35 oranında optimize ettim.""";
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> adviceData = widget.cvData['career_advice'] ?? {};
    String displayText = "";
    dynamic rawAnalysis = _overrideAdvice ?? widget.cvData['ai_analysis'] ?? widget.cvData['summary'] ?? adviceData['summary'];

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
        displayText.toLowerCase().contains("error") ||
        displayText.contains("Realistic Fit Analysis") ||
        displayText.contains("Here is the critical assessment")) {
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
              IconButton(
                onPressed: _isRefreshing ? null : _refreshAnalysis,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                tooltip: "Yenile",
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