/// Centralized ATS score resolution logic.
/// Used by HomeScreen, AiCoachScreen, and AtsScoreCard so the fallback
/// behaviour ("if root score is 0, use best match's score") is consistent
/// across the whole app.
class MatchHelper {
  /// Resolves the best ATS score from [cvData] and its [jobMatches] list.
  ///
  /// Priority:
  ///  1. Pre-computed `_resolved_ats_score` stored after upload-time fetch.
  ///  2. Root-level `ats_score` / `atsScore` (int or Map with total_score).
  ///  3. Best job match's `ats_score` or `match_percentage`.
  ///  4. Falls back to 0.
  static int resolveAtsScore(
    Map<String, dynamic> cvData,
    List<dynamic> jobMatches,
  ) {
    // 0. Pre-computed value stored at upload time
    final precomputed = cvData['_resolved_ats_score'];
    if (precomputed is num && precomputed > 0) return precomputed.toInt();

    // 1. Root-level ats_score
    var rawScore = cvData['ats_score'] ?? cvData['atsScore'];
    if (rawScore is num && rawScore > 0) return rawScore.toInt();
    if (rawScore is Map) {
      final s = rawScore['ats_score'] ?? rawScore['atsScore'] ?? rawScore['total_score'] ?? rawScore['totalScore'] ?? 0;
      if (s is num && s > 0) return s.toInt();
    }

    // 2. Best match from jobMatches
    for (var job in jobMatches) {
      if (job is! Map) continue;
      final jobMap = Map<String, dynamic>.from(job);
      
      final scoreInt = jobMap['match_score_int'];
      if (scoreInt is num && scoreInt > 0) return scoreInt.toInt();

      final atsDet = jobMap['ats_details'];
      if (atsDet is Map && atsDet['ats_score'] != null) {
        final s = atsDet['ats_score'];
        if (s is num && s > 0) return s.toInt();
      }

      final jobAts = jobMap['ats_score'] ?? jobMap['atsScore'];
      if (jobAts is num && jobAts > 0) return jobAts.toInt();

      final matchPerc = jobMap['match_percentage'] ?? jobMap['matchPercentage'];
      if (matchPerc != null) {
        final s = int.tryParse(matchPerc.toString().replaceAll(RegExp(r'[^0-9]'), ''));
        if (s != null && s > 0) return s;
      }
    }

    return 0;
  }

  /// Returns all job matches stored in [cvData].
  static List<dynamic> getJobMatches(Map<String, dynamic> cvData) {
    return (cvData['job_matches'] ?? cvData['jobMatches'] ?? []) as List<dynamic>;
  }
}
