// main_layout.dart dosyasının güncellenmiş hali
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'ai_coach_screen.dart';
import 'jobs_screen.dart';
import 'cv_list_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Alt sekmelere tıklandıkça açılacak sayfaların listesi artık 4 tane
  final List<Widget> _pages = [
    const HomeScreen(),      // 0. İndeks: Dashboard
    const AiCoachScreen(),   // 1. İndeks: AI Koç
    const JobsScreen(),      // 2. İndeks: İş Fırsatları
    const CvListScreen(),    // 3. İndeks: CV'lerim
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        // 3'ten fazla öğe olduğunda kaymayı engellemek için fixed kullanmak çok önemlidir
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Özet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI Koç',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_rounded),
            label: 'İlanlar',
          ),
          // YENİ EKLENEN SEKME
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_shared_rounded),
            label: "CV'lerim",
          ),
        ],
      ),
    );
  }
}