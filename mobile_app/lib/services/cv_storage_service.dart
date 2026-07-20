import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CvStorageService {
  static const String _hasCvKey = 'has_cv_loaded';
  static const String _cvDataKey =
      'cv_analysis_data'; // Yeni: Veriyi tutacağımız anahtar

  Future<bool> checkHasCv() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCvKey) ?? false;
  }

  Future<void> setCvLoaded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCvKey, value);
  }

  // YENİ: Backend'den gelen analiz sonucunu JSON formatında kaydet
  Future<void> saveAnalysisData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cvDataKey, jsonEncode(data));
  }

  // YENİ: Kaydedilen veriyi ana sayfada göstermek için geri çağır
  Future<Map<String, dynamic>?> getAnalysisData() async {
    final prefs = await SharedPreferences.getInstance();
    String? dataString = prefs.getString(_cvDataKey);
    if (dataString != null) {
      return jsonDecode(dataString);
    }
    return null;
  }
}
