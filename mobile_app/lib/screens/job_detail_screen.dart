import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/skill_chip.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/cv_storage_service.dart';
import '../services/localization_service.dart';
import '../widgets/coach_markdown_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isBookmarked = false;
  bool _descExpanded = false;
  bool _outreachExpanded = false;

  late final String _jobId;
  late final String title;
  late final String company;
  late final String location;
  late final int atsScore;
  late final Map<String, dynamic>? atsDetails;
  late final List<String> matchedSkills;
  late final List<String> missingSkills;
  late final String description;
  String? salaryText;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _jobId = (job['id'] ?? job['_id'] ?? '${job["job_title"]}__${job["company"]}').toString();
    title = job['job_title'] ?? 'Pozisyon';
    company = job['company'] ?? 'Şirket';
    location = job['location'] ?? '';
    description = job['description'] ?? job['job_description'] ?? '';

    final rawSalary = job['salary'];
    if (rawSalary != null && rawSalary.toString().trim().isNotEmpty && rawSalary.toString().toLowerCase() != 'null') {
      salaryText = rawSalary.toString().trim();
    } else {
      salaryText = null;
    }

    final String matchPct = job['match_percentage']?.toString() ?? '%0';
    atsScore = job['match_score_int'] ??
        job['ats_details']?['ats_score'] ??
        int.tryParse(matchPct.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    atsDetails = job['ats_details'];
    matchedSkills = List<String>.from(job['matched_skills'] ?? []);
    missingSkills = List<String>.from(job['missing_skills'] ?? []);

    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final saved = await cvStorageService.isBookmarked(_jobId);
    if (mounted) setState(() => _isBookmarked = saved);
  }

  Future<void> _toggleBookmark() async {
    final newState = await cvStorageService.toggleBookmark(_jobId);
    if (mounted) {
      setState(() => _isBookmarked = newState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState ? context.loc('job_saved_msg') : context.loc('job_unsaved_msg')),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newState ? AppTheme.primaryColor : Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = atsScore >= 70
        ? const Color(0xFF22C55E)
        : (atsScore >= 40 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    final String rawDesc = (widget.job['description'] ?? widget.job['job_description'] ?? widget.job['snippet'] ?? '').toString();
    final String cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: IconButton(
              key: ValueKey(_isBookmarked),
              icon: Icon(
                _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                color: _isBookmarked
                    ? AppTheme.primaryColor
                    : (Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.grey.shade400),
              ),
              splashRadius: 24,
              onPressed: _toggleBookmark,
              tooltip: _isBookmarked ? 'Kayıttan çıkar' : 'Kaydet',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── a) BAŞLIK / ŞİRKET / LOKASYON ───────────────────────────
            _buildJobHeader(),
            const SizedBox(height: 20),

            // ─── YENİ: İŞ AÇIKLAMASI (STRIPPED HTML) ─────────────────────


            // ─── b) İLAN ÖZETİ ───────────────────────────────────────────
            if (description.isNotEmpty) ...[
              _buildDescriptionCard(),
              const SizedBox(height: 20),
            ],

            // ─── c) ATS UYUM SKORU ────────────────────────────────────────
            _buildAtsCard(scoreColor),
            const SizedBox(height: 20),

            // ─── d) EŞLEŞen / EKSİK BECERİLER ──────────────────────────
            _buildSkillsCard(),
            const SizedBox(height: 20),

            // ─── e) AI KOÇU KARTI ────────────────────────────────────────
            _buildAiCoachSection(),
            const SizedBox(height: 20),

            // ─── f) OUTREACH ASISTANI ────────────────────────────────────
            _buildOutreachSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ElevatedButton(
            onPressed: () async {
              final rawUrl = widget.job['url'] ?? widget.job['link'] ?? widget.job['apply_url'] ?? widget.job['redirect_url'] ?? widget.job['job_url'] ?? widget.job['jobUrl'];
              if (rawUrl != null && rawUrl.toString().isNotEmpty) {
                String finalUrl = rawUrl.toString().trim().replaceAll(' ', '%20');
                if (!finalUrl.toLowerCase().startsWith('http')) {
                  finalUrl = 'https://$finalUrl';
                }
                
                print('DEBUG - AÇILMAYA ÇALIŞILAN URL: $finalUrl');
                
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
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(context.loc('apply_now'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // ─── a) BAŞLIK / ŞİRKET / LOKASYON ─────────────────────────────────────────
  Widget _buildJobHeader() {
    String? salary = widget.job['salary']?.toString();
    if (salary != null && (salary.trim().isEmpty || salary.toLowerCase() == 'null')) {
      salary = null;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Şirket monogramı
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                company.isNotEmpty ? company.substring(0, 1).toUpperCase() : 'Ş',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppTheme.textLightColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLightColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: salary == null ? Colors.grey.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(salary == null ? Icons.money_off_csred_rounded : Icons.attach_money_rounded, size: 16, color: salary == null ? Colors.grey : Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        salary ?? "Maaş Belirtilmemiş",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: salary == null ? Colors.grey : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // ─── b) İLAN ÖZETİ (Read More) ──────────────────────────────────────────────
  Widget _buildDescriptionCard() {
    const int previewLines = 4;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.article_outlined, color: Color(0xFF0EA5E9), size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                context.loc('job_summary'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Text(
              description,
              maxLines: previewLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textLightColor,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textLightColor,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Row(
              children: [
                Text(
                  _descExpanded ? context.loc('show_less') : context.loc('read_more'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _descExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── c) ATS UYUM SKORU ──────────────────────────────────────────────────────
  Widget _buildAtsCard(Color scoreColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.analytics_outlined, color: scoreColor, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                context.loc('ats_score_title'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              Text(
                '%$atsScore',
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: atsScore / 100,
              minHeight: 10,
              backgroundColor: scoreColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          if (atsDetails != null && atsDetails!['details'] != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge(
                    label: context.loc('semantic_match'),
                    value: '${atsDetails!['details']['semantic_score'] ?? '-'}',
                    color: const Color(0xFF6B48FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatBadge(
                    label: context.loc('keyword_match'),
                    value: '${atsDetails!['details']['keyword_score'] ?? '-'}',
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textLightColor)),
        ],
      ),
    );
  }

  // ─── d) BECERILER ────────────────────────────────────────────────────────────
  Widget _buildSkillsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.verified_outlined,
                    color: Color(0xFF22C55E), size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                context.loc('skills_analysis'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '✓ ${context.loc('matched_skills')}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 10),
          if (matchedSkills.isEmpty)
            const Text('Eşleşen yetenek bulunamadı.',
                style: TextStyle(fontSize: 12, color: AppTheme.textLightColor))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matchedSkills.map((s) => SkillChip(label: s)).toList(),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF5F5FA), thickness: 1.5),
          ),
          Text(
            '⚠ ${context.loc('missing_skills')}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 10),
          if (missingSkills.isEmpty)
            const Text('Eksik yetenek bulunmuyor.',
                style: TextStyle(fontSize: 12, color: AppTheme.textLightColor))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missingSkills.map((s) => SkillChip(label: s, isMissing: true)).toList(),
            ),
        ],
      ),
    );
  }

  // ─── e) AI KOÇU KARTI ────────────────────────────────────────────────────────
  Widget _buildAiCoachSection() {
    if (missingSkills.isEmpty && atsScore >= 95) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.loc('perfect_match'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return FutureBuilder<String?>(
      future: ApiService.getCoachAdvice(
        title, 
        matchedSkills, 
        missingSkills, 
        atsScore,
        userProvider.skills,
        userProvider.experienceLevel, 
        lang: Localizations.localeOf(context).languageCode
      ),
      builder: (context, snapshot) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header şerit
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor.withValues(alpha: 0.08), Colors.white],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6B48FF), Color(0xFF48A6FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lightbulb_outline_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.loc('ai_coach'),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyLarge?.color)),
                        Text(context.loc('coach_desc'),
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('BETA',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF5F5FA), thickness: 1),
              // İçerik
              Padding(
                padding: const EdgeInsets.all(20),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                  color: AppTheme.primaryColor, strokeWidth: 2.5),
                              const SizedBox(height: 14),
                              Text(context.loc('coach_loading'),
                                  style: TextStyle(
                                      fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      )
                    : snapshot.hasError || !snapshot.hasData || snapshot.data == null
                        ? Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(context.loc('coach_error'),
                                    style: const TextStyle(color: Colors.red, fontSize: 13)),
                              ),
                            ],
                          )
                        : CoachMarkdownView(
                            markdownText: snapshot.data!,
                            onDarkBackground: false,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── f) OUTREACH ASISTANI ────────────────────────────────────────────────────
  Widget _buildOutreachSection() {
    final outreachText = '''
**Konu:** $title Pozisyonu İçin Bağlantı Talebi

Merhaba,

$company bünyesindeki **$title** pozisyonunu gördüm ve bu fırsat konusunda sizinle bağlantı kurmak istedim.

**Öne çıkan yetkinliklerim:**
${matchedSkills.take(3).map((s) => '- $s').join('\n')}

Profilinizi inceledim ve şirketinizin bu alanda yürüttüğü çalışmalar ilgimi çekti. 15 dakikalık kısa bir görüşme yapmak ister misiniz?

Teşekkürler ve kolay gelsin!
''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => setState(() => _outreachExpanded = !_outreachExpanded),
          icon: const Text('🪄', style: TextStyle(fontSize: 16)),
          label: Text(
            context.loc('outreach_btn'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_outreachExpanded) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        context.loc('outreach_card_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        color: AppTheme.primaryColor,
                        tooltip: context.loc('copy'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: outreachText.trim()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.loc('copied_msg')),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CoachMarkdownView(
                    markdownText: outreachText,
                    onDarkBackground: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}