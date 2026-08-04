import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  // Mock Data
  final List<String> _skills = [
    'Python', 
    'Flutter', 
    'FastAPI', 
    'PyTorch', 
    'OpenCV', 
    'MATLAB', 
    'YOLOv8'
  ];
  String _experienceLevel = 'Junior';

  // Getters
  List<String> get skills => _skills;
  String get experienceLevel => _experienceLevel;

  // Setters / Methods
  void setExperienceLevel(String level) {
    if (_experienceLevel != level) {
      _experienceLevel = level;
      notifyListeners();
    }
  }

  void addSkill(String skill) {
    final cleanSkill = skill.trim();
    if (cleanSkill.isNotEmpty && !_skills.contains(cleanSkill)) {
      _skills.add(cleanSkill);
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    if (_skills.contains(skill)) {
      _skills.remove(skill);
      notifyListeners();
    }
  }
}
