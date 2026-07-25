import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/cv_storage_service.dart';
import '../services/localization_service.dart';
import 'job_detail_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  bool _isLoading = true;
  List<dynamic> _allJobs = [];
  List<dynamic> _filteredJobs = [];
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  int _skip = 0;
  final int _limit = 20;
  bool _isFetchingMore = false;
  int _totalJobs = 0;

  String _selectedCountryKey = "all";
  String _selectedTab = 'all';
  Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBookmarks();
    _loadAllJobs();
    cvStorageService.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    _loadAllJobs();
    _loadBookmarks();
  }

  @override
  void dispose() {
    cvStorageService.removeListener(_onStorageChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _fetchMoreJobs();
    }
  }

  Future<void> _fetchMoreJobs() async {
    if (_isFetchingMore || _allJobs.length >= _totalJobs) return;
    setState(() => _isFetchingMore = true);
    
    try {
      final storedData = await cvStorageService.getAnalysisData();
      final String countryCode;
      switch (_selectedCountryKey) {
        case 'america': countryCode = 'US'; break;
        case 'uk': countryCode = 'UK'; break;
        case 'germany': countryCode = 'DE'; break;
        default: countryCode = 'ALL';
      }
      final newData = await ApiService.fetchMatches(
        skills: storedData?['parsed_skills'] as List<dynamic>?,
        country: countryCode,
        skip: _skip,
        limit: _limit,
      );
      
      if (!mounted) return;
      
      if (newData != null) {
        final newMatches = newData['matches'] as List<dynamic>? ?? [];
        if (newMatches.isNotEmpty) {
          setState(() {
            _allJobs.addAll(newMatches);
            // Tarihe göre azalan (en yeni en üstte) sıralama
            _allJobs.sort((a, b) {
              final dateA = (a['published_at'] ?? '').toString();
              final dateB = (b['published_at'] ?? '').toString();
              return dateB.compareTo(dateA);
            });
            _totalJobs = newData['total'] ?? _totalJobs;
            _skip += _limit;
            _filterJobs(_searchController.text);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching more jobs: $e");
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  // --- TÜM İLANLARI VE EŞLEŞME ORANLARINI ÇEKME ---
  Future<void> _loadAllJobs() async {
    if (mounted) setState(() => _isLoading = true);
    _skip = 0;
    try {
      final storedData = await cvStorageService.getAnalysisData();
      final String countryCode;
      switch (_selectedCountryKey) {
        case 'america': countryCode = 'US'; break;
        case 'uk': countryCode = 'UK'; break;
        case 'germany': countryCode = 'DE'; break;
        default: countryCode = 'ALL';
      }
      final liveData = await ApiService.fetchMatches(
        skills: storedData?['parsed_skills'] as List<dynamic>?,
        country: countryCode,
        skip: _skip,
        limit: _limit,
      );

      if (!mounted) return;

      if (liveData != null) {
        setState(() {
          _allJobs = liveData['matches'] as List<dynamic>? ?? [];
          // Tarihe göre azalan sıralama
          _allJobs.sort((a, b) {
            final dateA = (a['published_at'] ?? '').toString();
            final dateB = (b['published_at'] ?? '').toString();
            return dateB.compareTo(dateA);
          });
          _totalJobs = liveData['total'] ?? 0;
          _filteredJobs = List.from(_allJobs);
          if (_allJobs.isNotEmpty) {
             _skip += _limit;
          }
        });
      } else {
        if (!mounted) return;

        if (storedData != null && storedData['job_matches'] != null) {
          setState(() {
            _allJobs = storedData['job_matches'];
            _filteredJobs = storedData['job_matches'];
          });
        }
      }
    } catch (e) {
      debugPrint("İlanlar çekilirken hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Bookmark listesini yerel depolamadan yükleme
  Future<void> _loadBookmarks() async {
    final ids = await cvStorageService.getBookmarkedIds();
    if (mounted) setState(() => _bookmarkedIds = ids);
  }

  // Bookmark toggle
  Future<void> _toggleBookmark(String jobId) async {
    final newState = await cvStorageService.toggleBookmark(jobId);
    if (mounted) {
      setState(() {
        if (newState) {
          _bookmarkedIds.add(jobId);
        } else {
          _bookmarkedIds.remove(jobId);
          // Kaydedilenler sekmesindeyken ilan listeden düşüyor
          if (_selectedTab == 'saved') {
            _filteredJobs.removeWhere((j) => _jobId(j) == jobId);
          }
        }
      });
    }
  }

  /// Her ilan için tutarlı bir ID üretir (backend'den geliyorsa id alanı, yoksa başlık+şirket hash'i)
  String _jobId(dynamic job) {
    return (job['id'] ?? job['_id'] ?? '${job["job_title"]}__${job["company"]}').toString();
  }

  // Arama çubuğu filtresi
  void _filterJobs(String query) {
    final source = _selectedTab == 'saved'
        ? _allJobs.where((j) => _bookmarkedIds.contains(_jobId(j))).toList()
        : _allJobs;

    if (query.isEmpty) {
      setState(() => _filteredJobs = source);
    } else {
      setState(() {
        _filteredJobs = source.where((job) {
          final title = (job['job_title'] ?? job['title'] ?? '').toString().toLowerCase();
          final company = (job['company'] ?? '').toString().toLowerCase();
          final location = (job['location'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return title.contains(q) || company.contains(q) || location.contains(q);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.loc('all_jobs'), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadAllJobs, // Ekranı aşağı kaydırınca tüm ilanları yeniler
        child: Column(
          children: [
            // 1. ARAMA ÇUBUĞU
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterJobs,
                decoration: InputDecoration(
                  hintText: context.loc('search_position'),
                  hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterJobs('');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTab == 'saved'
                        ? "${_filteredJobs.length} kaydedilen ilan"
                        : _searchController.text.isEmpty
                            ? "$_totalJobs ilan listeleniyor"
                            : "${_filteredJobs.length} sonuç bulundu",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLightColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Icon(Icons.tune_rounded, size: 20, color: Colors.grey.shade400),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // SEKMELİ FİLTRE: Tüm İlanlar / Kaydedilenler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildTabChip('all', Icons.format_list_bulleted_rounded, context.loc('all_jobs')),
                  const SizedBox(width: 8),
                  _buildTabChip('saved', Icons.bookmark_rounded, context.loc('saved_jobs')),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 2.5 ÜLKE FİLTRELERİ
            _buildCountryFilters(),
            const SizedBox(height: 8),

            // 3. İLAN LİSTESİ
            Expanded(
              child: _filteredJobs.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Text(context.loc('no_jobs_found'), style: AppTheme.descriptionStyle.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ),
                ],
              )
                  : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(16.0),
                itemCount: _filteredJobs.length + (_isFetchingMore ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == _filteredJobs.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                    );
                  }
                  return _buildJobCard(context, _filteredJobs[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SEKME ÇİPlİ (Tüm / Kaydedilenler) ---
  Widget _buildTabChip(String tab, IconData icon, String label) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
          _filterJobs(_searchController.text);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ÜLKE FİLTRELERİ ---
  Widget _buildCountryFilters() {
    final filters = ['all', 'america', 'uk', 'germany'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: filters.map((filterKey) {
          bool isSelected = _selectedCountryKey == filterKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                  context.loc(filterKey),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  )
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && _selectedCountryKey != filterKey) {
                  setState(() {
                    _selectedCountryKey = filterKey;
                  });
                  _loadAllJobs();
                }
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppTheme.primaryColor,
              showCheckmark: false,
              side: BorderSide(color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- İLAN KARTI TASARIMI (Modern / Minimal) ---
  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    String title = job['job_title'] ?? job['title'] ?? 'Pozisyon';
    String company = job['company'] ?? 'Şirket';
    String location = job['location'] ?? '';
    final String jobId = _jobId(job);
    final bool isBookmarked = _bookmarkedIds.contains(jobId);

    var rawAts = job['ats_score'] ?? job['atsScore'];
    int matchValue;
    if (rawAts != null) {
      matchValue = (rawAts as num).toInt();
    } else {
      String matchStr = (job['match_percentage'] ?? '%0').toString().replaceAll(RegExp(r'[^0-9]'), '');
      matchValue = int.tryParse(matchStr) ?? 0;
    }

    final Color scoreColor = matchValue >= 80
        ? const Color(0xFF22C55E)
        : (matchValue >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black.withValues(alpha: 0.035)
                  : Colors.transparent,
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ŞİRKET MONOGRAMİ
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  company.isNotEmpty ? company.substring(0, 1).toUpperCase() : "Ş",
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ORTA: Başlık + Şirket + Lokasyon
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    location.isNotEmpty ? "$company • $location" : company,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // SAĞ: Skor + Bookmark
            Row(
              children: [
                // Dairesel Skor Göstergesi
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: matchValue / 100,
                          strokeWidth: 4,
                          backgroundColor: scoreColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        "%$matchValue",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bookmark Butonu
                IconButton(
                  onPressed: () => _toggleBookmark(jobId),
                  splashRadius: 24,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      key: ValueKey(isBookmarked),
                      color: isBookmarked
                          ? AppTheme.primaryColor
                          : (Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.grey.shade400),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}