import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CvStorageService extends ChangeNotifier {
  static const String _cvDataKey =
      'cv_analysis_data'; // Yeni: Veriyi tutacağımız anahtar

  static const String _cvListKey = 'cv_list_data';

  List<Map<String, dynamic>> _memoryList = [];
  Set<String> _memoryBookmarks = {};

  bool get hasCv => _memoryList.isNotEmpty;
  
  Map<String, dynamic>? get activeCv {
    try {
      return _memoryList.firstWhere((cv) => cv['isPrimary'] == true);
    } catch (e) {
      return _memoryList.isNotEmpty ? _memoryList.first : null;
    }
  }

  List<Map<String, dynamic>> get cvList => _memoryList;
  Set<String> get bookmarkedIds => _memoryBookmarks;

  /// Call this once at app startup (e.g. in splash screen or main.dart)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load CV List
    String? dataString = prefs.getString(_cvListKey);
    if (dataString != null) {
      List<dynamic> decoded = jsonDecode(dataString);
      _memoryList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      String? oldData = prefs.getString(_cvDataKey);
      if (oldData != null) {
        Map<String, dynamic> cv = jsonDecode(oldData);
        cv['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        cv['title'] = "Varsayılan CV";
        cv['date'] = "Mevcut";
        cv['isPrimary'] = true;
        _memoryList = [cv];
        await saveCvList(_memoryList, notify: false);
        await prefs.remove(_cvDataKey);
      }
    }

    // Load Bookmarks
    final bList = prefs.getStringList(_bookmarksKey) ?? [];
    _memoryBookmarks = bList.toSet();
    
    notifyListeners();
  }

  Future<bool> checkHasCv() async {
    return hasCv;
  }

  Future<List<Map<String, dynamic>>> getCvList() async {
    return _memoryList;
  }

  Future<void> saveCvList(List<Map<String, dynamic>> list, {bool notify = true}) async {
    _memoryList = list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cvListKey, jsonEncode(list));
    if (notify) notifyListeners();
  }

  Future<void> addCv(Map<String, dynamic> data, String fileName, {bool notify = true}) async {
    bool isFirst = _memoryList.isEmpty;
    data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    data['title'] = fileName;
    data['date'] = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    data['isPrimary'] = isFirst; // İlk CV otomatik primary olur
    
    final newList = List<Map<String, dynamic>>.from(_memoryList)..add(data);
    await saveCvList(newList, notify: notify);
  }

  Future<void> deleteCv(String id, {bool notify = true}) async {
    final newList = List<Map<String, dynamic>>.from(_memoryList);
    newList.removeWhere((cv) => cv['id'] == id);
    if (newList.isNotEmpty && !newList.any((cv) => cv['isPrimary'] == true)) {
      newList[0]['isPrimary'] = true;
    }
    await saveCvList(newList, notify: notify);
  }

  Future<void> setPrimary(String id, {bool notify = true}) async {
    final newList = List<Map<String, dynamic>>.from(_memoryList);
    for (var cv in newList) {
      cv['isPrimary'] = (cv['id'] == id);
    }
    await saveCvList(newList, notify: notify);
  }

  // Ana ekranlar için mevcut varsayılan CV'yi döndürür
  Future<Map<String, dynamic>?> getAnalysisData() async {
    return activeCv;
  }

  /// Belirli bir CV'nin (id ile eşleşen) verisini günceller.
  /// Yeni eşleşmeler veya skorlar yazıldığında kullanılır.
  Future<void> updateCvData(Map<String, dynamic> updatedData, {bool notify = true}) async {
    final newList = List<Map<String, dynamic>>.from(_memoryList);
    final idx = newList.indexWhere((cv) => cv['id'] == updatedData['id']);
    if (idx != -1) {
      newList[idx] = updatedData;
      await saveCvList(newList, notify: notify);
    }
  }

  // ─── BOOKMARK (Kaydedilen İlanlar) ───────────────────────────────────────

  static const String _bookmarksKey = 'saved_job_ids';

  Future<Set<String>> getBookmarkedIds() async {
    return _memoryBookmarks;
  }

  Future<bool> isBookmarked(String jobId) async {
    return _memoryBookmarks.contains(jobId);
  }

  Future<bool> toggleBookmark(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_memoryBookmarks.contains(jobId)) {
      _memoryBookmarks.remove(jobId);
    } else {
      _memoryBookmarks.add(jobId);
    }
    await prefs.setStringList(_bookmarksKey, _memoryBookmarks.toList());
    notifyListeners();
    return _memoryBookmarks.contains(jobId);
  }
}

// Global Singleton Instance
final cvStorageService = CvStorageService();
