import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/settings_service.dart';

import 'services/cv_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settingsService.loadSettings();
  await cvStorageService.init();
  runApp(const CareerLensApp());
}

class CareerLensApp extends StatelessWidget {
  const CareerLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CareerLens AI',
          themeMode: settingsService.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppTheme.backgroundColor,
            cardColor: AppTheme.surfaceColor,
            dividerColor: Colors.black.withValues(alpha: 0.05),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.light().textTheme,
            ).copyWith(
              bodyMedium: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textColor,
              ),
              bodyLarge: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppTheme.textColor,
              ),
              titleLarge: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
              titleMedium: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
              labelSmall: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E2C), // Koyu lacivert/gri tonu
            ),
            scaffoldBackgroundColor: const Color(0xFF12121A), // Çok koyu lacivert (göz yormayan siyah alternatifi)
            cardColor: const Color(0xFF1E1E2C),
            dividerColor: const Color(0xFF2A2A3C),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.dark().textTheme,
            ).copyWith(
              bodyMedium: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white70,
              ),
              bodyLarge: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: Colors.white,
              ),
              titleLarge: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              titleMedium: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              labelSmall: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white70,
              ),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}