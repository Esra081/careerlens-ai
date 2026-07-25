import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../services/cv_storage_service.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/match_helper.dart';

class CvListScreen extends StatefulWidget {
  const CvListScreen({super.key});

  @override
  State<CvListScreen> createState() => _CvListScreenState();
}

class _CvListScreenState extends State<CvListScreen> {
  List<Map<String, dynamic>> _cvList = [];
  bool _isLoading = false;
  bool _isUploading = false; // "Yeni CV Yükle" butonu için ayrı bir yüklenme state'i

  @override
  void initState() {
    super.initState();
    _loadCvs();
  }

  Future<void> _loadCvs() async {
    setState(() => _isLoading = true);
    final list = await cvStorageService.getCvList();
    if (mounted) {
      setState(() {
        _cvList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewCv() async {
    if (_isUploading) return; // Çift tıklamayı engelle

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
        });

        PlatformFile file = result.files.single;
        final analysisData = await ApiService.uploadCv(file);

        if (analysisData != null) {
          await cvStorageService.addCv(analysisData, file.name, notify: false);

          // --- Anında Eşleşme Tetiklemesi ---
          // CV eklenir eklenmez, en güncel ilanları çekip CV verisine yaz.
          // notify: false verdiğimiz için ana ekran tetiklenmeyecek, ta ki updateCvData çalışana kadar.
          try {
            final skills = analysisData['parsed_skills'] as List<dynamic>?;
            final matchResult = await ApiService.fetchMatches(
              skills: skills,
              country: 'ALL',
              skip: 0,
              limit: 10,
            );
            if (matchResult != null) {
              final matches = matchResult['matches'] as List<dynamic>? ?? [];
              // Skor hesapla ve CV verisine yaz
              final resolvedScore = MatchHelper.resolveAtsScore(analysisData, matches);
              analysisData['job_matches'] = matches;
              analysisData['_resolved_ats_score'] = resolvedScore;
              // Güncel veriyi storage'a kaydet ve dinleyicileri tetikle
              await cvStorageService.updateCvData(analysisData, notify: true);
            } else {
              // Eşleşme gelmezse bile boş haliyle tetikle
              await cvStorageService.updateCvData(analysisData, notify: true);
            }
          } catch (e) {
            debugPrint('İlk eşleşme çekme hatası (CV yükleme sonrası): $e');
          }

          await _loadCvs(); // Listeyi yenile
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.loc('cv_upload_success')),
                backgroundColor: Colors.green.shade600,
              ),
            );
          }
        } else {
          throw Exception("API sunucusundan veri alınamadı. Backend loglarını kontrol edin.");
        }
      }
    } catch (e) {
      debugPrint("CV Yükleme Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${context.loc('cv_upload_error')}: $e"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteCv(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc('delete_cv_title')),
        content: Text(context.loc('delete_cv_content')),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text(context.loc('cancel'), style: const TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(context.loc('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      await cvStorageService.deleteCv(id);
      await _loadCvs();
    }
  }

  Future<void> _setPrimary(String id) async {
    setState(() => _isLoading = true);
    // 1. Önce notify yapmadan varsayılan seç
    await cvStorageService.setPrimary(id, notify: false);
    
    // 2. Yeni varsayılan CV'yi çek ve eşleşmeleri kontrol et
    final cvData = await cvStorageService.getAnalysisData();
    if (cvData != null) {
      final existingMatches = MatchHelper.getJobMatches(cvData);
      if (existingMatches.isEmpty) {
        try {
          final skills = cvData['parsed_skills'] as List<dynamic>?;
          final matchResult = await ApiService.fetchMatches(
            skills: skills,
            country: 'ALL',
            skip: 0,
            limit: 10,
          );
          if (matchResult != null) {
            final matches = matchResult['matches'] as List<dynamic>? ?? [];
            final resolvedScore = MatchHelper.resolveAtsScore(cvData, matches);
            cvData['job_matches'] = matches;
            cvData['_resolved_ats_score'] = resolvedScore;
            // 3. Eşleşme geldiyse güncelleyerek tetikle
            await cvStorageService.updateCvData(cvData, notify: true);
          } else {
             await cvStorageService.updateCvData(cvData, notify: true);
          }
        } catch (e) {
          debugPrint('Set Primary eşleşme çekme hatası: $e');
          await cvStorageService.updateCvData(cvData, notify: true);
        }
      } else {
        // Eşleşmesi zaten varsa, dummy bir update ile tetikleyebiliriz
        await cvStorageService.updateCvData(cvData, notify: true);
      }
    }
    await _loadCvs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.loc('my_cvs'), style: AppTheme.titleStyle.copyWith(color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_cvList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(context.loc('no_cv_yet'), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  )
                else
                  ..._cvList.map((cv) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Dismissible(
                          key: Key(cv['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                          ),
                          onDismissed: (direction) {
                            _deleteCv(cv['id']);
                          },
                          child: _buildCvCard(
                            id: cv['id'],
                            title: cv['title'] == 'Varsayılan CV' ? context.loc('default_cv') : (cv['title'] ?? context.loc('untitled_cv')),
                            date: cv['date'] == 'Mevcut' ? context.loc('available') : (cv['date'] ?? ''),
                            isPrimary: cv['isPrimary'] == true,
                          ),
                        ),
                      )),

                const SizedBox(height: 16),

                // Yeni CV Ekleme Butonu
                InkWell(
                  onTap: _isUploading ? null : _addNewCv,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isUploading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.add_box_outlined, color: AppTheme.primaryColor),
                        
                        const SizedBox(width: 12),
                        Text(
                          _isUploading ? context.loc('analyzing') : context.loc('upload_new_cv'),
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
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
  Widget _buildCvCard({required String id, required String title, required String date, required bool isPrimary}) {
    return GestureDetector(
      onTap: () {
        if (!isPrimary) _setPrimary(id);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? Border.all(color: AppTheme.primaryColor, width: 2) : Border.all(color: Theme.of(context).dividerColor),
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
                color: Colors.red.withValues(alpha: 0.05),
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
                  Text(title, style: AppTheme.subtitleStyle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("${context.loc('uploaded')}: $date", style: AppTheme.descriptionStyle.copyWith(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                ],
              ),
            ),
            
            // SİLME İKONU (YENİ EKLENEN)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
              onPressed: () => _deleteCv(id),
              padding: const EdgeInsets.only(right: 8.0),
              constraints: const BoxConstraints(),
            ),

            if (isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(context.loc('active'), style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            else
              Radio<String>(
                value: id,
                groupValue: isPrimary ? id : null,
                onChanged: (val) {
                  _setPrimary(id);
                },
                activeColor: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}