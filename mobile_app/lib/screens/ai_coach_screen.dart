import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/cv_storage_service.dart';
import '../services/api_service.dart';
import '../services/match_helper.dart';
import '../widgets/ats_score_card.dart';
import '../widgets/skills_radar_chart.dart';
import '../widgets/career_coach_card.dart';
import '../services/localization_service.dart';

// Dynamic planner generates steps on the fly based on CV skills

// (Dynamic content replaces these)

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  bool _isLoading = true;
  bool _hasCv = false;
  Map<String, dynamic>? _cvData;

  // Planner state
  double _plannerMonths = 3;
  bool _plannerExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    cvStorageService.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    _loadData();
  }

  @override
  void dispose() {
    cvStorageService.removeListener(_onStorageChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    final hasCv = await cvStorageService.checkHasCv();
    if (hasCv) {
      _cvData = await cvStorageService.getAnalysisData();
      if (_cvData != null) {
        final existingMatches = MatchHelper.getJobMatches(_cvData!);
        if (existingMatches.isEmpty) {
          try {
            final skills = _cvData!['parsed_skills'] as List<dynamic>?;
            final result = await ApiService.fetchMatches(
              skills: skills,
              country: 'ALL',
              skip: 0,
              limit: 10,
            );
            if (result != null) {
              final matches = result['matches'] as List<dynamic>? ?? [];
              final resolvedScore = MatchHelper.resolveAtsScore(_cvData!, matches);
              _cvData!['job_matches'] = matches;
              _cvData!['_resolved_ats_score'] = resolvedScore;
              await cvStorageService.updateCvData(_cvData!);
            }
          } catch (e) {
            debugPrint('AI Koç – eşleşme çekme hatası: $e');
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _hasCv = hasCv;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.loc('ai_coach_title'),
            style: AppTheme.titleStyle.copyWith(
                color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        key: ValueKey<bool>(_isLoading),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : (!_hasCv || _cvData == null)
                ? _buildEmptyState()
                : _buildDashboard(),
      ),
    );
  }

  // ─── Boş durum ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined,
                  size: 64, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(context.loc('no_analysis'),
                style: AppTheme.titleStyle.copyWith(
                    color: Theme.of(context).textTheme.titleLarge?.color)),
            const SizedBox(height: 12),
            Text(context.loc('no_analysis_desc'),
                style: AppTheme.descriptionStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Ana Dashboard ─────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final jobMatches = MatchHelper.getJobMatches(_cvData!);
    final bestMatch = jobMatches.isNotEmpty
        ? Map<String, dynamic>.from(jobMatches.first as Map)
        : <String, dynamic>{};

    final enrichedCvData = Map<String, dynamic>.from(_cvData!);
    final matched = bestMatch['matched_skills'] ?? bestMatch['matchedSkills'] ?? [];
    final missing = bestMatch['missing_skills'] ?? bestMatch['missingSkills'] ?? [];
    if ((matched as List).isNotEmpty) enrichedCvData['matched_skills'] = matched;
    if ((missing as List).isNotEmpty) enrichedCvData['missing_skills'] = missing;

    // Dinamik Rota (Modül 1 ve Modül 2) Üretimi
    List<String> topSkills = [];
    if (enrichedCvData['parsed_skills'] != null) {
      topSkills = List<String>.from(enrichedCvData['parsed_skills']).take(4).toList();
    }
    if (topSkills.isEmpty) topSkills = ['Teknoloji', 'Yazılım', 'Proje', 'Geliştirme'];

    final Map<String, List<String>> titlePool = {
      'Python': ['Backend Developer', 'AI/ML Engineer', 'Data Scientist'],
      'YOLOv8': ['Computer Vision Engineer', 'AI Researcher'],
      'OpenCV': ['Computer Vision Engineer', 'Image Processing Engineer'],
      'MATLAB': ['Systems Engineer', 'Simulation Engineer', 'Research Scientist'],
      'React': ['Frontend Developer', 'UI Engineer', 'Full Stack Developer'],
      'Flutter': ['Mobile App Developer', 'Flutter Engineer'],
      'Java': ['Backend Developer', 'Software Engineer', 'Enterprise Developer'],
      'C++': ['Game Developer', 'Embedded Systems Engineer', 'C++ Developer'],
      'SQL': ['Data Analyst', 'Database Administrator', 'Data Engineer'],
      'Docker': ['DevOps Engineer', 'Cloud Engineer'],
      'AWS': ['Cloud Architect', 'DevOps Engineer'],
      'Kubernetes': ['DevOps Engineer', 'Platform Engineer'],
      'Machine Learning': ['Machine Learning Engineer', 'AI/ML Developer'],
      'Deep Learning': ['AI Researcher', 'Deep Learning Engineer'],
    };

    final dynamicRoles = topSkills.map((skill) {
      // Anahtar kelime eşleşmesi (Büyük/küçük harf duyarsız)
      String matchKey = titlePool.keys.firstWhere(
        (key) => skill.toLowerCase().contains(key.toLowerCase()),
        orElse: () => '',
      );

      String roleTitle = matchKey.isNotEmpty 
          ? titlePool[matchKey]!.first 
          : 'Software Engineer';
          
      return _SuggestedRole(
        title: roleTitle,
        projectIdea: '$skill tabanlı yenilikçi end-to-end uygulama',
        icon: Icons.work_outline,
        color: const Color(0xFF6B48FF),
      );
    }).toList();

    final dynamicCourses = topSkills.map((skill) => _CourseItem(
      title: 'İleri Seviye $skill Masterclass',
      provider: 'Udemy / Coursera · ~10 saat',
      icon: Icons.school,
      color: const Color(0xFF48A6FF),
    )).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(context.loc('deep_analysis'),
              style: AppTheme.titleStyle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.titleLarge?.color)),
          const SizedBox(height: 6),
          Text(context.loc('deep_analysis_desc'),
              style: AppTheme.descriptionStyle.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color)),
          const SizedBox(height: 28),

          // ── AI Taviye Kartı ─────────────────────────────────────────────
          CareerCoachCard(cvData: enrichedCvData),
          const SizedBox(height: 28),

          // ── ATS Skoru ──────────────────────────────────────────────────
          AtsScoreCard(cvData: enrichedCvData),
          const SizedBox(height: 28),

          // ── Yetenek Radarı ──────────────────────────────────────────────
          SkillsRadarChart(cvData: enrichedCvData),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // MODÜL 1 — Uygun Unvanlar & Proje Önerileri
          // ═══════════════════════════════════════════════════════════════
          _sectionTitle(context.loc('suitable_roles'), Icons.work_outline_rounded),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dynamicRoles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _buildRoleCard(dynamicRoles[i]),
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // MODÜL 2 — Gelişim Radarı (Kurslar & Sertifikalar)
          // ═══════════════════════════════════════════════════════════════
          _sectionTitle(context.loc('dev_radar'), Icons.school_outlined),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: dynamicCourses.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(c.icon, color: c.color, size: 20),
                      ),
                      title: Text(c.title,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color)),
                      subtitle: Text(c.provider,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7))),
                    ),
                    if (i < dynamicCourses.length - 1)
                      Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Theme.of(context).dividerColor),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // MODÜL 3 — İnteraktif Planlayıcı
          // ═══════════════════════════════════════════════════════════════
          _sectionTitle(context.loc('interactive_planner'), Icons.map_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.loc('planner_duration'),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_plannerMonths.toInt()} ${context.loc('month')}',
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor:
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: _plannerMonths,
                    min: 1,
                    max: 6,
                    divisions: 5,
                    onChanged: (v) => setState(() {
                      _plannerMonths = v;
                      _plannerExpanded = false;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _plannerExpanded = !_plannerExpanded),
                    icon: Icon(
                        _plannerExpanded
                            ? Icons.close_rounded
                            : Icons.route_rounded,
                        size: 18),
                    label: Text(
                      _plannerExpanded
                          ? context.loc('planner_hide')
                          : context.loc('planner_draw'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                if (_plannerExpanded) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  ..._buildPlanSteps(context),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Yardımcı: Bölüm başlığı ────────────────────────────────────────────
  Widget _sectionTitle(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: AppTheme.titleStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color)),
      ],
    );
  }

  // ─── Yardımcı: Rol kartı ─────────────────────────────────────────────────
  Widget _buildRoleCard(_SuggestedRole role) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: role.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(role.icon, color: role.color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(role.title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Expanded(
            child: Text(role.projectIdea,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─── Yardımcı: Plan adımları ─────────────────────────────────────────────
  List<Widget> _buildPlanSteps(BuildContext context) {
    final months = _plannerMonths.toInt();
    
    List<String> topSkills = [];
    if (_cvData != null) {
      final parsed = _cvData!['parsed_skills'] ?? _cvData!['parsedSkills'];
      if (parsed != null) {
        topSkills = List<String>.from(parsed).take(6).toList();
      }
    }
    
    if (topSkills.isEmpty) {
      topSkills = ['Python', 'Docker', 'FastAPI', 'AWS', 'Kaggle', 'Portfolio'];
    }

    List<String> dynamicSteps = [];
    for (int i = 1; i <= months; i++) {
      String skill = topSkills[(i - 1) % topSkills.length];
      if (months <= 3) {
        dynamicSteps.add("**Hafta ${(i*2)-1}–${i*2}:** $skill teknolojisinde uzmanlaş ve küçük çaplı bir proje başlat.");
      } else {
        dynamicSteps.add("**Ay $i:** $skill odaklı uçtan uca (end-to-end) bir proje geliştir ve GitHub portföyüne ekle.");
      }
    }

    final steps = dynamicSteps;

    return steps.asMap().entries.map((entry) {
      final i = entry.key;
      final step = entry.value;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: AppTheme.primaryColor, shape: BoxShape.circle),
                child: Center(
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ),
              if (i < steps.length - 1)
                Container(
                    width: 2,
                    height: 36,
                    color: AppTheme.primaryColor.withValues(alpha: 0.25)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: i < steps.length - 1 ? 24 : 0, top: 4),
              child: Text(
                // Strip ** manually for plain display
                step.replaceAll('**', ''),
                style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}

// ─── Data classes ────────────────────────────────────────────────────────────
class _SuggestedRole {
  final String title;
  final String projectIdea;
  final IconData icon;
  final Color color;
  const _SuggestedRole({
    required this.title,
    required this.projectIdea,
    required this.icon,
    required this.color,
  });
}

class _CourseItem {
  final String title;
  final String provider;
  final IconData icon;
  final Color color;
  const _CourseItem({
    required this.title,
    required this.provider,
    required this.icon,
    required this.color,
  });
}