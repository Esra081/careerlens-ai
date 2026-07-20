import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("İş Eşleşmeleri", style: AppTheme.titleStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Alt çubukta olduğumuz için geri tuşunu gizler
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Profilinize Uygun Fırsatlar",
            style: AppTheme.titleStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            "Yapay zeka, CV'nizi aşağıdaki ilanlar için analiz etti ve eşleşme oranlarını hesapladı.",
            style: AppTheme.captionStyle,
          ),
          const SizedBox(height: 24),

          // 1. İş İlanı Kartı
          _buildJobCard(
            context,
            jobTitle: "Computer Vision Engineer",
            companyName: "SOYLU Aerospace",
            matchPercentage: 0.95,
            tags: ["PyTorch", "YOLO", "OpenCV"],
          ),
          const SizedBox(height: 16),

          // 2. İş İlanı Kartı
          _buildJobCard(
            context,
            jobTitle: "AI Researcher (2209-A Destekli)",
            companyName: "TÜBİTAK",
            matchPercentage: 0.88,
            tags: ["LLM", "NLP", "Python"],
          ),
          const SizedBox(height: 16),

          // 3. İş İlanı Kartı
          _buildJobCard(
            context,
            jobTitle: "Software Engineering Intern",
            companyName: "Ankara Bilgi Teknolojileri",
            matchPercentage: 0.85,
            tags: ["Flutter", "Dart", "Mobile"],
          ),
        ],
      ),
    );
  }

  // İş İlanı Kartı Tasarım Metodu
  Widget _buildJobCard(
      BuildContext context, {
        required String jobTitle,
        required String companyName,
        required double matchPercentage,
        required List<String> tags,
      }) {
    int percent = (matchPercentage * 100).toInt();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Eşleşme Oranı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: AppTheme.subtitleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(companyName, style: AppTheme.captionStyle),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "%$percent Uyum",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Etiketler (Yetenekler)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textColor),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Aksiyon Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Burada ilana özel CV oluşturma ekranına veya fonksiyona gidilecek
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$companyName için CV uyarlanıyor...")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text("Bu İlan İçin CV'mi Uyarla", style: AppTheme.actionButtonStyle),
            ),
          ),
        ],
      ),
    );
  }
}