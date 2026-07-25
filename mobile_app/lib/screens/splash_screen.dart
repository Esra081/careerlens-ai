import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/cv_storage_service.dart';
import 'main_layout.dart';
import 'upload_cv_screen.dart';

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
    // Uygulama açıldığında ekranda 1.5 saniye logonun görünmesi için kısa bir bekleme (Gerçekçi hissettirir)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Hafızayı kontrol et: CV yüklü mü?
    bool hasCv = await cvStorageService.checkHasCv();

    if (mounted) {
      if (hasCv) {
        // DURUM 1: CV daha önceden yüklenmişse direkt Ana İskelete (Dashboard vb.) yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      } else {
        // DURUM 2: CV hiç yüklenmemişse direkt CV Yükleme ekranına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UploadCvScreen()),
        );
      }
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