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
    if (precomputed is int && precomputed > 0) return precomputed;

    // 1. Root-level ats_score
    var rawScore = cvData['ats_score'] ?? cvData['atsScore'];
    if (rawScore is int && rawScore > 0) return rawScore;
    if (rawScore is Map) {
      final s = rawScore['total_score'] ?? rawScore['totalScore'] ?? 0;
      if (s is int && s > 0) return s;
    }

    // 2. Fallback – best match from jobMatches
    if (jobMatches.isNotEmpty) {
      final firstJob = jobMatches.first as Map<String, dynamic>;
      final jobAts = firstJob['ats_score'] ?? firstJob['atsScore'];
      if (jobAts != null) return (jobAts as num).toInt();

      final matchPerc = firstJob['match_percentage'] ?? firstJob['matchPercentage'];
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
