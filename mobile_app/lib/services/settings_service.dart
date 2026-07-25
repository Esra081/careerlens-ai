import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';

  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'tr'; // Varsayılan TR

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme Mode
    final themeStr = prefs.getString(_themeKey);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Language Code
    _languageCode = prefs.getString(_languageKey) ?? 'tr';

    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_themeKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString(_themeKey, 'dark');
    } else {
      await prefs.setString(_themeKey, 'system');
    }
  }

  Future<void> updateLanguage(String langCode) async {
    if (langCode == _languageCode) return;
    _languageCode = langCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);
  }
}

// Global instance of SettingsService to easily access from main.dart
final settingsService = SettingsService();
