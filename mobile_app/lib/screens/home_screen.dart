import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/bento_card.dart';
import '../services/cv_storage_service.dart';
import 'job_detail_screen.dart';
import 'upload_cv_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CvStorageService _storageService = CvStorageService();
  bool _isLoading = true;
  bool _hasCv = false;
  Map<String, dynamic>? _cvData;
  String _selectedFilter = "Tümü";

  @override
  void initState() {
    super.initState();
    _checkCvStatus();
  }

  Future<void> _checkCvStatus() async {
    bool hasCv = await _storageService.checkHasCv();
    if (hasCv) {
      _cvData = await _storageService.getAnalysisData();
    }
    setState(() {
      _hasCv = hasCv;
      _isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Günaydın,";
    if (hour >= 12 && hour < 18) return "İyi günler,";
    if (hour >= 18 && hour < 22) return "İyi akşamlar,";
    return "İyi geceler,";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        key: ValueKey<bool>(_isLoading),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : (_hasCv ? _buildDashboardState(context) : _buildEmptyState(context)),
      ),
    );
  }

  // --- ANA RENKLİ HEADER ---
  Widget _buildColoredHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 24, // Alt boşluğu biraz azalttık
          left: 24,
          right: 24
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text("E", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  const Text("Esra 👋", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildTransparentIconButton(Icons.notifications_none, hasBadge: true),
              const SizedBox(width: 12),
              _buildTransparentIconButton(Icons.settings_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransparentIconButton(IconData icon, {bool hasBadge = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Stack(
        children: [
          IconButton(icon: Icon(icon, color: Colors.white, size: 22), onPressed: () {}),
          if (hasBadge)
            Positioned(
              right: 10, top: 12,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            )
        ],
      ),
    );
  }

  // --- BOŞ DURUM ---
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildColoredHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_present_rounded, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 24),
                const Text("Henüz Bir CV Yüklemediniz", style: AppTheme.titleStyle, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text("Yapay zeka analizini görmek için ilk CV'nizi yükleyin.", style: AppTheme.descriptionStyle, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    bool? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadCvScreen()));
                    if (result == true) {
                      setState(() => _isLoading = true);
                      _checkCvStatus();
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("CV Yükle", style: AppTheme.buttonTextStyle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- ANA DASHBOARD ---
  Widget _buildDashboardState(BuildContext context) {
    List<dynamic> jobMatches = _cvData!['job_matches'] ?? [];
    int score = 0;
    var rawScore = _cvData!['ats_score'];
    if (rawScore is int) score = rawScore;
    else if (rawScore is Map) score = rawScore['total_score'] ?? 0;

    List<String> topSkills = [];
    if (_cvData!['parsed_skills'] != null) {
      topSkills = List<String>.from(_cvData!['parsed_skills']).take(4).toList();
    }

    return Column(
      children: [
        _buildColoredHeader(context),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SIKIŞTIRILMIŞ (COMPACT) VE DETAYLI CV KARTI
                _buildCompactHeroCvCard(score, topSkills),

                const SizedBox(height: 32),

                // 2. İŞ İLANLARI BAŞLIĞI VE FİLTRELER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Sizin İçin Seçilenler", style: AppTheme.titleStyle.copyWith(fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16)
                      ),
                      child: const Text("Daha Fazla Filtre", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuickFilters(),
                const SizedBox(height: 20),

                // 3. GÖRSELDEKİ İSKELETE UYGUN İŞ İLANI KARTLARI
                if (jobMatches.isEmpty)
                  const Text("Şu an için uygun ilan bulunamadı.", style: AppTheme.descriptionStyle)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobMatches.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildImageStyleJobCard(context, jobMatches[index]);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- GERÇEKÇİ MİNYATÜR CV TASARIMI (Geri Geldi!) ---
  Widget _buildCvThumbnail() {
    return Container(
      width: 56,
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 8, width: 28, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(height: 3, width: 20, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Spacer(),
          Row(
            children: [
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            ],
          )
        ],
      ),
    );
  }

  // --- SIKIŞTIRILMIŞ YENİ CV KARTI (Alan Verimliliği) ---
  Widget _buildCompactHeroCvCard(int score, List<String> topSkills) {
    return BentoCard(
      padding: const EdgeInsets.all(16), // Padding daraltıldı
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCvThumbnail(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Analiz Edilen CV", style: AppTheme.captionStyle),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text("%$score ATS", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Computer_Vision_CV.pdf", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textColor)),
                const SizedBox(height: 10),
                // Etiketler alt alta değil, yan yana dar bir alanda (Wrap)
                Wrap(
                  spacing: 6.0, runSpacing: 6.0,
                  children: topSkills.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(skill, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HIZLI FİLTRE ÇİPLERİ ---
  Widget _buildQuickFilters() {
    final filters = ["Tümü", "Yeni İlanlar", "Yüksek Eşleşme (>%80)", "Yazılım", "Uzaktan"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  )
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.textColor, // Görseldeki gibi koyu lacivert/siyah tonu
              showCheckmark: false,
              side: BorderSide(color: isSelected ? AppTheme.textColor : Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- GÖRSELE BİREBİR UYUMLU İŞ İLANI KARTI İSKELETİ ---
  Widget _buildImageStyleJobCard(BuildContext context, Map<String, dynamic> job) {
    String title = job['job_title'] ?? 'Pozisyon';
    String company = job['company'] ?? 'Şirket';
    String matchString = job['match_percentage'] ?? '%0';
    // "%98" şeklindeki metinden sadece sayıyı almak için ufak bir temizlik:
    String matchNum = matchString.replaceAll(RegExp(r'[^0-9]'), '');
    int matchValue = int.tryParse(matchNum) ?? 0;

    // Eşleşme oranına göre dairesel barın rengini belirliyoruz
    Color matchColor = matchValue >= 80 ? Colors.green : (matchValue >= 50 ? Colors.orange : Colors.red);

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5), // Görseldeki gibi hafif belirgin sınır
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Column(
        children: [
          // ÜST KISIM: Logo, Başlık, Dairesel Skor
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LOGO
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(company.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),

                // ORTA METİNLER (Pozisyon ve Şirket/Lokasyon)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor)),
                      const SizedBox(height: 6),
                      Text("$company | Tam Zamanlı", style: AppTheme.captionStyle.copyWith(fontSize: 13)),
                    ],
                  ),
                ),

                // GÖRSELDEKİ GİBİ DAİRESEL EŞLEŞME SKORU
                SizedBox(
                  width: 64, height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64, height: 64,
                        child: CircularProgressIndicator(
                          value: matchValue / 100,
                          strokeWidth: 5,
                          backgroundColor: Colors.grey.shade200,
                          color: matchColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$matchValue%", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: matchColor)),
                          const Text("Eşleşme", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1.5),

          // ALT KISIM: İki Eşit Buton (Hızlı Başvur ve Kaydet)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // HIZLI BAŞVUR BUTONU (Koyu Renkli)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JobDetailScreen(job: job))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textColor, // Görseldeki gibi koyu lacivert
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Hızlı Başvur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),

                // KAYDET BUTONU (Açık Gri)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border, size: 18, color: AppTheme.textColor),
                    label: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: AppTheme.textColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}