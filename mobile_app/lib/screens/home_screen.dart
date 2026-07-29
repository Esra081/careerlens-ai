import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../widgets/bento_card.dart';
import '../services/cv_storage_service.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/match_helper.dart';
import 'job_detail_screen.dart';
import 'upload_cv_screen.dart';
import 'settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _selectedFilterKey = "all";
  Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    cvStorageService.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cvStorageService.removeListener(_onStorageChanged);
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final ids = await cvStorageService.getBookmarkedIds();
    if (mounted) setState(() => _bookmarkedIds = ids);
  }

  Future<void> _toggleBookmark(String jobId) async {
    final newState = await cvStorageService.toggleBookmark(jobId);
    if (mounted) {
      setState(() {
        if (newState) {
          _bookmarkedIds.add(jobId);
        } else {
          _bookmarkedIds.remove(jobId);
        }
      });
    }
  }

  String _jobId(dynamic job) {
    return (job['id'] ?? job['_id'] ?? '${job["job_title"]}__${job["company"]}').toString();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final activeCv = cvStorageService.activeCv;
      if (activeCv == null) return;
      
      final String countryCode;
      switch (_selectedFilterKey) {
        case 'america': countryCode = 'US'; break;
        case 'uk': countryCode = 'UK'; break;
        case 'germany': countryCode = 'DE'; break;
        default: countryCode = 'ALL';
      }
      
      final liveMatches = await ApiService.fetchMatches(
        skills: activeCv['parsed_skills'] as List<dynamic>?,
        country: countryCode,
        skip: 0,
        limit: 5,
      );
      
      activeCv['job_matches'] = liveMatches?['matches'] ?? [];
      await cvStorageService.updateCvData(activeCv, notify: true);
    } catch (e) {
      debugPrint("Error refreshing matches: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return context.loc('good_morning');
    if (hour >= 12 && hour < 18) return context.loc('good_afternoon');
    if (hour >= 18 && hour < 22) return context.loc('good_evening');
    return context.loc('good_night');
  }

  @override
  Widget build(BuildContext context) {
    final activeCv = cvStorageService.activeCv;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        key: ValueKey<bool>(_isLoading),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : (activeCv != null ? _buildDashboardState(context, activeCv) : _buildEmptyState(context)),
      ),
    );
  }

  Widget _buildColoredHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 24,
          left: 24,
          right: 24
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text("E", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(context), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  const Text("Esra 👋", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildTransparentIconButton(Icons.notifications_none, hasBadge: true),
              const SizedBox(width: 12),
              _buildTransparentIconButton(
                Icons.settings_outlined,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransparentIconButton(IconData icon, {bool hasBadge = false, VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Stack(
        children: [
          IconButton(icon: Icon(icon, color: Colors.white, size: 22), onPressed: onPressed ?? () {}),
          if (hasBadge)
            Positioned(
              right: 10, top: 12,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildColoredHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_present_rounded, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 24),
                Text(context.loc('no_cv_yet'), style: AppTheme.titleStyle.copyWith(color: Theme.of(context).textTheme.titleLarge?.color), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(context.loc('no_cv_desc'), style: AppTheme.descriptionStyle.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadCvScreen()));
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(context.loc('upload_cv'), style: AppTheme.buttonTextStyle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardState(BuildContext context, Map<String, dynamic> activeCv) {
    final jobMatches = activeCv['job_matches'] as List<dynamic>? ?? [];
    int score = MatchHelper.resolveAtsScore(activeCv, jobMatches);

    List<String> topSkills = [];
    var parsedSkills = activeCv['parsed_skills'] ?? activeCv['parsedSkills'];
    if (parsedSkills != null) {
      topSkills = List<String>.from(parsedSkills).take(4).toList();
    }

    return Column(
      children: [
        _buildColoredHeader(context),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactHeroCvCard(activeCv, score, topSkills),
                const SizedBox(height: 20),
                _buildSkillRadar(topSkills, jobMatches),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.loc('selected_for_you'), style: AppTheme.titleStyle.copyWith(fontSize: 18, color: Theme.of(context).textTheme.titleLarge?.color)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16)
                      ),
                      child: Text(context.loc('more_filters'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuickFilters(),
                const SizedBox(height: 20),
                if (jobMatches.isEmpty)
                  Text(context.loc('no_jobs_found'), style: AppTheme.descriptionStyle.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobMatches.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildImageStyleJobCard(context, jobMatches[index]);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCvThumbnail() {
    return Container(
      width: 56,
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.transparent,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 8, width: 28, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(height: 3, width: 20, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          const Spacer(),
          Row(
            children: [
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCompactHeroCvCard(Map<String, dynamic> activeCv, int score, List<String> topSkills) {
    String cvName = activeCv['title'] ?? activeCv['fileName'] ?? "Bilinmeyen CV";
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCvThumbnail(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        context.loc('analyzed_cv'), 
                        style: AppTheme.captionStyle.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text("%$score ATS", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(cvName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6.0, runSpacing: 6.0,
                  children: topSkills.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(skill, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = ['all', 'america', 'uk', 'germany'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filterKey) {
          bool isSelected = _selectedFilterKey == filterKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                context.loc(filterKey),
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedFilterKey = filterKey;
                  });
                  _refreshData();
                }
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageStyleJobCard(BuildContext context, Map<String, dynamic> job) {
    String title = job['job_title'] ?? job['title'] ?? 'Pozisyon';
    String company = job['company'] ?? 'Şirket';
    final String jobId = _jobId(job);
    final bool isBookmarked = _bookmarkedIds.contains(jobId);
    
    // Burada da snake_case ve camelCase fallback uygulayalım:
    var jobAtsScore = job['ats_score'] ?? job['atsScore'];
    int matchValue = 0;

    if (jobAtsScore != null) {
      matchValue = (jobAtsScore as num).toInt();
    } else {
      var matchPerc = job['match_percentage'] ?? job['matchPercentage'];
      String matchString = matchPerc?.toString() ?? '%0';
      String matchNum = matchString.replaceAll(RegExp(r'[^0-9]'), '');
      matchValue = int.tryParse(matchNum) ?? 0;
    }

    // Eşleşme oranına göre dairesel barın rengini belirliyoruz
    Color matchColor = matchValue >= 80 ? Colors.green : (matchValue >= 50 ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JobDetailScreen(job: job))),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5), // Görseldeki gibi hafif belirgin sınır
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black.withValues(alpha: 0.02)
                  : Colors.transparent,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
      ),
      child: Column(
        children: [
          // ÜST KISIM: Logo, Başlık, Dairesel Skor
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LOGO
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Center(
                    child: Text(company.substring(0, 1).toUpperCase(), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w900, fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),

                // ORTA METİNLER (Pozisyon ve Şirket/Lokasyon)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 6),
                      Text("$company | ${context.loc('full_time')}", style: AppTheme.captionStyle.copyWith(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                    ],
                  ),
                ),

                // GÖRSELDEKİ GİBİ DAİRESEL EŞLEŞME SKORU
                SizedBox(
                  width: 64, height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64, height: 64,
                        child: CircularProgressIndicator(
                          value: matchValue / 100,
                          strokeWidth: 5,
                          backgroundColor: Theme.of(context).dividerColor,
                          color: matchColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$matchValue%", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: matchColor)),
                          Text(context.loc('match'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1.5),

          // ALT KISIM: İki Eşit Buton (Hızlı Başvur ve Kaydet)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // HIZLI BAŞVUR BUTONU (Koyu Renkli)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      print('DEBUG - KARTTAYKI VERİLER: ${job.keys}');
                      final rawUrl = job['url'] ?? job['link'] ?? job['apply_url'] ?? job['redirect_url'] ?? job['job_url'] ?? job['jobUrl'];
                      if (rawUrl != null && rawUrl.toString().isNotEmpty) {
                        String finalUrl = rawUrl.toString().trim().replaceAll(' ', '%20');
                        if (!finalUrl.toLowerCase().startsWith('http')) {
                          finalUrl = 'https://$finalUrl';
                        }
                        
                        print('DEBUG - ANASAYFA URL DENENİYOR: $finalUrl');
                        
                        try {
                          final uri = Uri.tryParse(finalUrl);
                          if (uri != null) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            throw Exception("Invalid URI");
                          }
                        } catch (_) {
                          try {
                            final uri = Uri.tryParse(finalUrl);
                            if (uri != null) {
                              await launchUrl(uri, mode: LaunchMode.platformDefault);
                            } else {
                              throw Exception("Invalid URI");
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Link açılamadı: $finalUrl')),
                              );
                            }
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Başvuru linkine şu an ulaşılamıyor.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).textTheme.bodyLarge?.color, // Koyu modda beyaz, açıkta koyu
                      foregroundColor: Theme.of(context).cardColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(context.loc('quick_apply'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),

                // KAYDET BUTONU (Açık Gri)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleBookmark(jobId),
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border,
                      size: 18,
                      color: isBookmarked
                          ? AppTheme.primaryColor
                          : (Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.grey.shade400),
                    ),
                    label: Text(
                      isBookmarked ? context.loc('saved') : context.loc('save'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isBookmarked ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBookmarked 
                          ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                          : (Theme.of(context).brightness == Brightness.light ? const Color(0xFFF3F4F6) : Colors.grey.shade800),
                      foregroundColor: isBookmarked 
                          ? AppTheme.primaryColor 
                          : (Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white70),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    ));
  }

  // --- YETENEk RADARI ---
  Widget _buildSkillRadar(List<String> topSkills, List<dynamic> jobMatches) {
    // Eşleşen skill setini her durumda hazırla
    final Set<String> matchedSet = {};
    for (var job in jobMatches.take(3)) {
      final m = job['matched_skills'] ?? job['matchedSkills'] ?? [];
      for (var s in m) { matchedSet.add(s.toString().toLowerCase()); }
    }

    // Kart başlığı — her zaman gösterilir
    final header = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B48FF), Color(0xFF48A6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc('skill_radar'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            Text(
              context.loc('radar_desc'),
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ],
    );

    // --- GUARD: 3'ten az beceri varsa Fallback UI ---
    if (topSkills.length < 3) {
      return BentoCard(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 20),
            // Mevcut becerileri yine de göster (varsa)
            if (topSkills.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topSkills.map((skill) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Bilgi mesajı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.loc('not_enough_skills_for_chart'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // --- NORMAL DURUM: Radar çizimi ---
    final radarSkills = topSkills.take(6).toList();
    final int n = radarSkills.length;

    // Değerleri 0-100 aralığında deterministik olarak belirle (NaN/Infinity riski yok)
    final List<double> values = radarSkills.asMap().entries.map((e) {
      final skillLower = e.value.toLowerCase();
      // Eşleşen → 80-95 bandı, sadece CV'de → 55-75 bandı (her zaman pozitif, sonlu değer)
      if (matchedSet.contains(skillLower)) {
        return (80.0 + (e.key % 3) * 5.0).clamp(0.0, 100.0);
      }
      return (55.0 + (e.key % 4) * 5.0).clamp(0.0, 100.0);
    }).toList();

    return BentoCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                // maxValue açıkça belirlendi — grafik motoru NaN/Infinity üretemiyor
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFF6B48FF).withValues(alpha: 0.18),
                    borderColor: const Color(0xFF6B48FF),
                    borderWidth: 2,
                    entryRadius: 4,
                    dataEntries: List.generate(
                      n,
                      (i) => RadarEntry(value: values[i]),
                    ),
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
                gridBorderData: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                titlePositionPercentageOffset: 0.22,
                titleTextStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                getTitle: (index, angle) {
                  if (index < 0 || index >= radarSkills.length) {
                    return const RadarChartTitle(text: '', angle: 0);
                  }
                  final skill = radarSkills[index];
                  final label = skill.length > 10 ? '${skill.substring(0, 9)}…' : skill;
                  return RadarChartTitle(text: label, angle: 0);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Alt beceri etiketleri
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: radarSkills.map((skill) {
              final isMatched = matchedSet.contains(skill.toLowerCase());
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMatched
                      ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMatched
                        ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  skill,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isMatched ? const Color(0xFF16A34A) : AppTheme.primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
