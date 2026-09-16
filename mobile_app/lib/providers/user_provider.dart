import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final List<String> _skills = [];
  String _experienceLevel = 'Junior';

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSkills = prefs.getStringList('saved_skills');
    final savedExperience = prefs.getString('saved_experience');

    if (savedSkills != null && savedSkills.isNotEmpty) {
      _skills.clear();
      _skills.addAll(savedSkills);
    } else {
      // Kurtarma mekanizması: Eğer saved_skills boşsa, kayıtlı CV listesindeki aktif CV'den çek
      final cvListStr = prefs.getString('cv_list_data');
      if (cvListStr != null) {
        try {
          final List<dynamic> list = jsonDecode(cvListStr);
          final activeCv = list.firstWhere((e) => e['isPrimary'] == true, orElse: () => list.isNotEmpty ? list.first : null);
          if (activeCv != null) {
            final dynamic rawSkills = activeCv['parsed_skills'] ?? activeCv['skills'];
            if (rawSkills is List) {
              _skills.clear();
              for (var s in rawSkills) {
                final str = s.toString().trim();
                if (str.isNotEmpty && !_skills.contains(str)) {
                  _skills.add(str);
                }
              }
              await prefs.setStringList('saved_skills', _skills);
            }
            final exp = activeCv['experience_level']?.toString();
            if (exp != null && exp.isNotEmpty) {
              _experienceLevel = exp;
              await prefs.setString('saved_experience', _experienceLevel);
            }
          }
        } catch (e) {
          debugPrint("UserProvider CV kurtarma hatası: $e");
        }
      }
    }

    if (savedExperience != null) {
      _experienceLevel = savedExperience;
    }
    notifyListeners();
  }

  Future<void> _saveSkills() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_skills', _skills);
  }

  Future<void> _saveExperience() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_experience', _experienceLevel);
  }

  // Getters
  List<String> get skills => _skills;
  String get experienceLevel => _experienceLevel;

  // Setters / Methods
  void setExperienceLevel(String level) {
    if (_experienceLevel != level) {
      _experienceLevel = level;
      _saveExperience();
      notifyListeners();
    }
  }

  Future<void> clearSkills() async {
    if (_skills.isNotEmpty) {
      _skills.clear();
      await _saveSkills();
      notifyListeners();
    }
  }

  Future<void> addSkill(String skill) async {
    final cleanSkill = skill.trim();
    if (cleanSkill.isNotEmpty && !_skills.contains(cleanSkill)) {
      _skills.add(cleanSkill);
      await _saveSkills();
      notifyListeners();
    }
  }

  Future<void> removeSkill(String skill) async {
    if (_skills.contains(skill)) {
      _skills.remove(skill);
      await _saveSkills();
      notifyListeners();
    }
  }

  Future<void> setSkills(List<String> newSkills) async {
    _skills.clear();
    for (var s in newSkills) {
      final clean = s.trim();
      if (clean.isNotEmpty && !_skills.contains(clean)) {
        _skills.add(clean);
      }
    }
    await _saveSkills();
    notifyListeners();
  }

  Future<void> syncFromCvData(Map<String, dynamic>? cvData) async {
    if (cvData == null) return;
    final target = (cvData['data'] is Map<String, dynamic>) ? cvData['data'] as Map<String, dynamic> : cvData;
    final dynamic rawSkills = target['parsed_skills'] ?? target['skills'] ?? target['extracted_skills'];
    if (rawSkills is List) {
      _skills.clear();
      for (var s in rawSkills) {
        final clean = s.toString().trim();
        if (clean.isNotEmpty && !_skills.contains(clean)) {
          _skills.add(clean);
        }
      }
      await _saveSkills();
    }
    final exp = (target['experience_level'] ?? target['experience'])?.toString();
    if (exp != null && exp.isNotEmpty) {
      _experienceLevel = exp;
      await _saveExperience();
    }
    notifyListeners();
  }
}
