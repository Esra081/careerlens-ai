import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/cv_storage_service.dart';
import 'main_layout.dart';
import 'upload_cv_screen.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstScreen();
  }

  Future<void> _checkFirstScreen() async {
    // Uygulama açıldığında logonun görünmesi için kısa bekleme
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // 1. Önce Oturum Kontrolü (Giriş yapılmış mı?)
    if (!authService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // 2. Giriş yapılmışsa CV kontrolü
    bool hasCv = await cvStorageService.checkHasCv();

    if (!mounted) return;

    if (hasCv) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UploadCvScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İleride buraya kendi uygulama logonu koyabilirsin
            Icon(Icons.auto_awesome, size: 80, color: AppTheme.primaryColor),
            SizedBox(height: 24),
            Text(
              "CareerLens AI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}