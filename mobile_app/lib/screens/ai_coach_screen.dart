import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/cv_storage_service.dart';
import '../widgets/ats_score_card.dart';
import '../widgets/skills_radar_chart.dart';
import '../widgets/career_coach_card.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final CvStorageService _storageService = CvStorageService();
  bool _isLoading = true;
  bool _hasCv = false;
  Map<String, dynamic>? _cvData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    bool hasCv = await _storageService.checkHasCv();
    if (hasCv) {
      _cvData = await _storageService.getAnalysisData();
    }
    setState(() {
      _hasCv = hasCv;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("AI Kariyer Koçu", style: AppTheme.titleStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Alt menüde olacağı için geri butonuna gerek yok
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        key: ValueKey<bool>(_isLoading),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : (!_hasCv || _cvData == null)
            ? _buildEmptyState()
            : _buildAnalysisState(context),
      ),
    );
  }

  // DURUM 1: CV YÜKLENMEMİŞSE
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined, size: 64, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text("Analiz Bulunamadı", style: AppTheme.titleStyle),
            const SizedBox(height: 12),
            const Text(
              "Yapay zeka analizini ve gelişim rotanızı görebilmek için lütfen ana sayfadan bir CV yükleyin.",
              style: AppTheme.descriptionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // DURUM 2: CV VARSA (Derinlemesine Analiz Ekranı)
  Widget _buildAnalysisState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Derinlemesine Analiz",
            style: AppTheme.titleStyle.copyWith(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            "Yetenekleriniz, eksikleriniz ve yapay zekanın hedeflerinize ulaşmanız için çizdiği özel rota.",
            style: AppTheme.descriptionStyle,
          ),
          const SizedBox(height: 32),

          // 1. EN ÜSTTE VURUCU AI TAVSİYESİ (Glassmorphism Kartı)
          CareerCoachCard(cvData: _cvData!),
          const SizedBox(height: 24),

          // 2. DETAYLI ATS SKORU
          AtsScoreCard(cvData: _cvData!),
          const SizedBox(height: 24),

          // 3. YETKİNLİK RADARI / ETİKETLERİ
          SkillsRadarChart(cvData: _cvData!),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}