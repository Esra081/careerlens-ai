import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  // Sınıf seviyesinde statik bir Dio instance'ı
  static final Dio _dio = Dio();
  // Fiziksel telefon için bilgisayarın yerel IP'si kullanılır. Emülatörde
  // `--dart-define=API_BASE_URL=http://10.0.2.2:8000` ile değiştirilebilir.
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.102:8000',
  );

  // --- CV YÜKLEME ---
  static Future<Map<String, dynamic>?> uploadCv(PlatformFile file) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });

      Response response = await _dio.post(
        "$_baseUrl/api/v1/analyze-cv",
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );

      if (response.statusCode == 200) {
        // Gelen yanıtın yapısına göre güvenli veri çekme
        if (response.data is Map) {
          var returnData = response.data['data'];
          if (returnData == null || returnData is! Map) {
            returnData = Map<String, dynamic>.from(response.data);
          } else {
            returnData = Map<String, dynamic>.from(returnData);
          }

          // Brute-force AI Analysis extraction
          dynamic rawAnalysis = response.data['ai_analysis'] 
                             ?? returnData['ai_analysis'] 
                             ?? response.data['career_advice'] 
                             ?? returnData['career_advice'] 
                             ?? response.data['summary'] 
                             ?? returnData['summary'];
          
          if (rawAnalysis != null) {
            if (rawAnalysis is String) {
              returnData['ai_analysis'] = rawAnalysis;
            } else if (rawAnalysis is Map || rawAnalysis is List) {
              try {
                returnData['ai_analysis'] = jsonEncode(rawAnalysis);
              } catch (e) {
                returnData['ai_analysis'] = rawAnalysis.toString();
              }
            } else {
              returnData['ai_analysis'] = rawAnalysis.toString();
            }
          }
          return Map<String, dynamic>.from(returnData);
        }
      }
      return null;
    } catch (e) {
      print("Dosya yükleme hatası: $e");
      return null;
    }
  }

  // --- İLANLARI ÇEKME (DİO İLE GÜNCELLENDİ) ---
  // null yalnızca istek başarısız olduğunda döner; boş liste geçerli bir
  // güncel yanıttır ve eski ilanlarla değiştirilmemelidir.
  static Future<Map<String, dynamic>?> fetchMatches({List<dynamic>? skills, String country = "ALL", int skip = 0, int limit = 20}) async {
    try {
      final queryParameters = <String, dynamic>{
        '_': DateTime.now().millisecondsSinceEpoch,
        'country': country,
        'skip': skip,
        'limit': limit,
      };
      if (skills != null && skills.isNotEmpty) {
        queryParameters['skills'] = skills.join(',');
      }

      Response response = await _dio.get(
        "$_baseUrl/api/v1/matches",
        queryParameters: queryParameters,
        options: Options(headers: const {
          'Cache-Control': 'no-cache, no-store, max-age=0',
          'Pragma': 'no-cache',
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final mappedData = Map<String, dynamic>.from(data);
          return {
            'total': mappedData['total'] ?? 0,
            'matches': mappedData['matches'] ?? [],
          };
        }
      }
    } catch (e) {
      print("API Bağlantı Hatası (Matches): $e");
    }
    return null;
  }

  // --- AI KARİYER KOÇU ---
  static Future<String?> getCoachAdvice(String targetRole, List<String> matchedSkills, List<String> missingSkills, int atsScore) async {
    try {
      Response response = await _dio.post(
        "$_baseUrl/api/v1/ai/coach",
        data: {
          "target_role": targetRole,
          "matched_skills": matchedSkills,
          "missing_skills": missingSkills,
          "ats_score": atsScore,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        return response.data['coach_advice'];
      }
    } catch (e) {
      print("AI Coach API Hatası: $e");
    }
    return null;
  }
}
