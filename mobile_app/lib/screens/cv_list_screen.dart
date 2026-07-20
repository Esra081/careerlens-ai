import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CvListScreen extends StatelessWidget {
  const CvListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("CV'lerim", style: AppTheme.titleStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Yüklü olan mevcut CV
          _buildCvCard(
            title: "Yazılım Mühendisi CV",
            date: "17 Temmuz 2026",
            fileType: "PDF",
            isPrimary: true,
          ),
          const SizedBox(height: 16),

          // Yeni CV Ekleme Butonu
          InkWell(
            onTap: () {
              // İleride burada UploadCvScreen() veya direkt file_picker açılabilir
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), style: BorderStyle.solid),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_box_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    "Yeni CV Yükle",
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // CV'leri listelemek için özel kart tasarımı
  Widget _buildCvCard({required String title, required String date, required String fileType, required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dosya İkonu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
          ),
          const SizedBox(width: 16),
          // Başlık ve Tarih
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.subtitleStyle),
                const SizedBox(height: 4),
                Text("Yüklendi: $date", style: AppTheme.descriptionStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          // Ana CV etiketi veya Menü
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text("Aktif", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}