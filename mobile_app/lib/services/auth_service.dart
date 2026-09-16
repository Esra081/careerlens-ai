import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'careerlens_auth_token';
  static const String _userKey = 'careerlens_auth_user';

  String? _token;
  UserModel? _currentUser;
  bool _isInitialized = false;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isInitialized => _isInitialized;

  /// Uygulama açılışında kayıtlı oturumu yükler.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJsonStr = prefs.getString(_userKey);

    if (userJsonStr != null && userJsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJsonStr) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(decoded);
      } catch (e) {
        debugPrint("Kayıtlı kullanıcı verisi çözülemedi: $e");
      }
    }

    // Token varsa arka planda profilin güncelliğini doğrula
    if (_token != null) {
      ApiService.setAuthToken(_token);
      _fetchCurrentUserProfile();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Arka planda sunucudan güncel profil bilgisini çeker
  Future<void> _fetchCurrentUserProfile() async {
    try {
      final user = await ApiService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Profil senkronizasyon hatası: $e");
    }
  }

  /// Kullanıcı girişi
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await ApiService.login(email.trim(), password);
    if (result['success'] == true) {
      _token = result['token'] as String?;
      _currentUser = result['user'] as UserModel?;

      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
        ApiService.setAuthToken(_token);
      }
      if (_currentUser != null) {
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }

      notifyListeners();
      return {'success': true};
    } else {
      return {
        'success': false,
        'message': result['message'] ?? 'Giriş yapılamadı.',
      };
    }
  }

  /// Kullanıcı kaydı
  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    final result = await ApiService.register(fullName.trim(), email.trim(), password);
    if (result['success'] == true) {
      _token = result['token'] as String?;
      _currentUser = result['user'] as UserModel?;

      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
        ApiService.setAuthToken(_token);
      }
      if (_currentUser != null) {
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }

      notifyListeners();
      return {'success': true};
    } else {
      return {
        'success': false,
        'message': result['message'] ?? 'Kayıt oluşturulamadı.',
      };
    }
  }

  /// Oturumu kapatır ve yerel verileri temizler
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    ApiService.setAuthToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }
}

// Global Singleton Instance
final authService = AuthService();
