import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../screens/job_detail_screen.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    String title = job['job_title'] ?? job['title'] ?? 'Pozisyon';
    String company = job['company'] ?? 'Şirket';
    String location = job['location'] ?? '';

    var rawAts = job['ats_score'] ?? job['atsScore'];
    int matchValue;
    if (rawAts != null) {
      matchValue = (rawAts as num).toInt();
    } else {
      String matchStr = (job['match_percentage'] ?? '%0').toString().replaceAll(RegExp(r'[^0-9]'), '');
      matchValue = int.tryParse(matchStr) ?? 0;
    }

    final Color scoreColor = matchValue >= 80
        ? const Color(0xFF10B981)
        : (matchValue >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    String? salaryText;
    final rawSalary = job['salary'];
    if (rawSalary != null && rawSalary.toString().trim().isNotEmpty && rawSalary.toString().toLowerCase() != 'null') {
      salaryText = rawSalary.toString().trim();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black.withValues(alpha: 0.025)
                  : Colors.transparent,
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  company.isNotEmpty ? company.substring(0, 1).toUpperCase() : "Ş",
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.isNotEmpty ? "$company • $location" : company,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  salaryText != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_money_rounded, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 2),
                              Text(
                                salaryText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.money_off_csred_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                            const SizedBox(width: 4),
                            Text(
                              "Maaş Belirtilmemiş",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$matchValue%",
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}