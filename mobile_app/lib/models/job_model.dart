class AtsDetailsModel {
  final int atsScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final Map<String, dynamic> details;

  AtsDetailsModel({
    required this.atsScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.details,
  });

  factory AtsDetailsModel.fromJson(Map<String, dynamic> json) {
    return AtsDetailsModel(
      atsScore: (json['ats_score'] as num?)?.toInt() ?? 0,
      matchedSkills: (json['matched_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      missingSkills: (json['missing_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ats_score': atsScore,
      'matched_skills': matchedSkills,
      'missing_skills': missingSkills,
      'details': details,
    };
  }
}

class JobModel {
  final String id;
  final String jobTitle;
  final String company;
  final String location;
  final String? url;
  final String publishedAt;
  final int matchScoreInt;
  final String matchPercentage;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final AtsDetailsModel? atsDetails;
  final String? salary;
  final String description;

  JobModel({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.location,
    this.url,
    required this.publishedAt,
    required this.matchScoreInt,
    required this.matchPercentage,
    required this.matchedSkills,
    required this.missingSkills,
    this.atsDetails,
    this.salary,
    required this.description,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? json['title']?.toString() ?? 'Pozisyon',
      company: json['company']?.toString() ?? 'Gizli Şirket',
      location: json['location']?.toString() ?? 'Belirtilmemiş',
      url: json['url']?.toString() ?? json['link']?.toString() ?? json['apply_url']?.toString(),
      publishedAt: json['published_at']?.toString() ?? '',
      matchScoreInt: (json['match_score_int'] as num?)?.toInt() ?? 
                     (json['ats_score'] as num?)?.toInt() ?? 0,
      matchPercentage: json['match_percentage']?.toString() ?? '%0',
      matchedSkills: (json['matched_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      missingSkills: (json['missing_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      atsDetails: json['ats_details'] is Map<String, dynamic>
          ? AtsDetailsModel.fromJson(json['ats_details'] as Map<String, dynamic>)
          : null,
      salary: json['salary']?.toString(),
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_title': jobTitle,
      'company': company,
      'location': location,
      'url': url,
      'published_at': publishedAt,
      'match_score_int': matchScoreInt,
      'match_percentage': matchPercentage,
      'matched_skills': matchedSkills,
      'missing_skills': missingSkills,
      'ats_details': atsDetails?.toJson(),
      'salary': salary,
      'description': description,
    };
  }
}
