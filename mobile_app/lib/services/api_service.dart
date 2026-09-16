import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class ApiService {
  // Sınıf seviyesinde statik bir Dio instance'ı
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  // Backend Base URL
  // Android Studio Emülatörü için bilgisayarın localhost'una '10.0.2.2' ile erişilir.
  // Fiziksel telefonda çalıştırırken: --dart-define=API_BASE_URL=http://<PC_IP>:8000 verilebilir.
  static String get _baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) return definedUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000'; // Android Studio Emülatörü
    }
    return 'http://127.0.0.1:8000'; // Windows Desktop / Web / iOS Simülatör
  }


  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  // ─── AUTHENTICATION (KULLANICI İŞLEMLERİ) ──────────────────────────────────

  static Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/api/v1/auth/register",
        data: {
          "full_name": fullName,
          "email": email,
          "password": password,
        },
      );
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return {
          'success': true,
          'token': token,
          'user': user,
        };
      }
      return {'success': false, 'message': 'Kayıt başarısız.'};
    } on DioException catch (e) {
      String msg = 'Kayıt olurken bir hata oluştu.';
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        msg = e.response?.data['detail'].toString() ?? msg;
      } else if (e.response == null) {
        msg = 'Sunucuya bağlanılamadı. Lütfen backend servisinin (uvicorn) çalıştığından emin olun.';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/api/v1/auth/login",
        data: {
          "email": email,
          "password": password,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return {
          'success': true,
          'token': token,
          'user': user,
        };
      }
      return {'success': false, 'message': 'Giriş başarısız.'};
    } on DioException catch (e) {
      String msg = 'Giriş yapılırken bir hata oluştu.';
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        msg = e.response?.data['detail'].toString() ?? msg;
      } else if (e.response == null) {
        msg = 'Sunucuya bağlanılamadı. Lütfen backend servisinin (uvicorn) çalıştığından emin olun.';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dio.get("$_baseUrl/api/v1/auth/me");
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Kullanıcı profili alınamadı: $e");
    }
    return null;
  }

  // --- FCM TOKEN KAYDETME ---
  static Future<void> sendFcmToken(String token) async {
    try {
      // Eğer kullanıcı giriş yapmışsa kullanıcıya özel auth endpoint'ine de yolla
      if (_authToken != null) {
        await _dio.post(
          "$_baseUrl/api/v1/auth/fcm-token",
          data: {"fcm_token": token},
        );
      } else {
        await _dio.post(
          "$_baseUrl/api/v1/fcm-token",
          data: {"token": token},
        );
      }
    } catch (e) {
      debugPrint("Token gönderim hatası: $e");
    }
  }


  static Future<Map<String, dynamic>?> uploadCv(PlatformFile file, {String lang = 'tr'}) async {
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
        queryParameters: {'lang': lang},
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

          // Extract AI Analysis text cleanly
          dynamic adviceObj = returnData['career_advice'] ?? response.data['career_advice'];
          String? summaryFromAdvice;
          if (adviceObj is Map && adviceObj['summary'] != null) {
            summaryFromAdvice = adviceObj['summary'].toString();
          }

          dynamic rawAnalysis = summaryFromAdvice
                             ?? response.data['ai_analysis'] 
                             ?? returnData['ai_analysis'] 
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
      debugPrint("Dosya yükleme hatası: $e");
      return null;
    }
  }

  // --- İLANLARI ÇEKME (DİO İLE GÜNCELLENDİ) ---
  // null yalnızca istek başarısız olduğunda döner; boş liste geçerli bir
  // güncel yanıttır ve eski ilanlarla değiştirilmemelidir.
  static Future<Map<String, dynamic>?> fetchMatches({
    List<dynamic>? skills,
    String experienceLevel = "Junior",
    String country = "ALL",
    int skip = 0,
    int limit = 20,
    String? experience,
    String? workModel,
    num? minSalary,
    String lang = 'tr',
  }) async {
    try {
      final payload = <String, dynamic>{
        'country': country,
        'skip': skip,
        'limit': limit,
        'lang': lang,
        'experience_level': experienceLevel,
      };
      if (skills != null && skills.isNotEmpty) {
        payload['skills'] = skills;
      } else {
        payload['skills'] = [];
      }
      if (experience != null && experience.isNotEmpty) {
        payload['experience'] = experience;
      }
      if (workModel != null && workModel.isNotEmpty) {
        payload['work_model'] = workModel;
      }
      if (minSalary != null && minSalary > 0) {
        payload['min_salary'] = minSalary.toInt();
      }

      Response response = await _dio.post(
        "$_baseUrl/api/v1/matches",
        data: payload,
        options: Options(headers: const {
          'Cache-Control': 'no-cache, no-store, max-age=0',
          'Pragma': 'no-cache',
          'Content-Type': 'application/json',
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
      debugPrint("API Bağlantı Hatası (Matches): $e");
    }
    return null;
  }

  // --- İLANLARI DIŞ KAYNAKTAN GÜNCELLE (INGEST) ---
  static Future<Map<String, dynamic>?> ingestJobs() async {
    try {
      Response response = await _dio.post("$_baseUrl/api/v1/jobs/ingest");
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("API Bağlantı Hatası (Ingest): $e");
    }
    return null;
  }

  // --- AI KARİYER KOÇU ---
  static Future<String?> getCoachAdvice(String targetRole, List<String> matchedSkills, List<String> missingSkills, int atsScore, List<String> skills, String experienceLevel, {String lang = 'tr'}) async {
    try {
      Response response = await _dio.post(
        "$_baseUrl/api/v1/ai/coach",
        data: {
          "target_role": targetRole,
          "matched_skills": matchedSkills,
          "missing_skills": missingSkills,
          "ats_score": atsScore,
          "skills": skills,
          "experience_level": experienceLevel,
          "lang": lang,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        return response.data['coach_advice'];
      }
    } catch (e) {
      debugPrint("AI Coach API Hatası: $e");
    }
    return null;
  }
}
