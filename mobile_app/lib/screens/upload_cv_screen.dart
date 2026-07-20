import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/cv_storage_service.dart';
import 'main_layout.dart'; // Yönlendirme için eklendi

class UploadCvScreen extends StatefulWidget {
  const UploadCvScreen({super.key});

  @override
  State<UploadCvScreen> createState() => _UploadCvScreenState();
}

class _UploadCvScreenState extends State<UploadCvScreen> {
  final ApiService _apiService = ApiService(); // Backend servisi
  bool _isLoading = false; // Yüklenme durumunu tutan değişken

  // Dosya seçme ve gönderme fonksiyonu
  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      PlatformFile file = result.files.first;

      // DEĞİŞEN KISIM: Artık isSuccess yerine analiz verisini bekliyoruz
      var analysisData = await _apiService.uploadCv(file);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Veri boş gelmediyse (başarılıysa)
        if (analysisData != null) {
          final storageService = CvStorageService();
          await storageService.setCvLoaded(true); // "CV var" yap
          await storageService.saveAnalysisData(analysisData); // VERİYİ KAYDET!

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dosya yüklenirken bir hata oluştu. Lütfen tekrar deneyin."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("CareerLens AI", style: AppTheme.titleStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.upload_file,
                size: 100,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 32),
              const Text(
                "Kariyer Analizi İçin\nCV'nizi Yükleyin",
                style: AppTheme.titleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Yapay zeka destekli sistemimiz CV'nizi analiz ederek size en uygun iş eşleşmelerini ve yetkinlik haritanızı çıkaracaktır.",
                style: AppTheme.descriptionStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Yüklenme durumuna göre buton veya animasyon gösterimi
              _isLoading
                  ? const Column(
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text("CV'niz yapay zeka tarafından analiz ediliyor...", style: AppTheme.descriptionStyle)
                ],
              )
                  : ElevatedButton(
                onPressed: _pickAndUploadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "CV Yükle (PDF, DOCX)",
                      style: AppTheme.buttonTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}