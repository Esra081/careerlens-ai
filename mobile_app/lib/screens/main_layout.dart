import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'ai_coach_screen.dart';
import 'jobs_screen.dart';
import 'cv_list_screen.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;



  List<_NavItem> _getNavItems(BuildContext context) {
    return [
      _NavItem(icon: Icons.space_dashboard_rounded, outlinedIcon: Icons.space_dashboard_outlined, label: context.loc('summary')),
      _NavItem(icon: Icons.auto_awesome, outlinedIcon: Icons.auto_awesome_outlined, label: context.loc('ai_coach')),
      _NavItem(icon: Icons.work_history_rounded, outlinedIcon: Icons.work_outline_rounded, label: context.loc('jobs')),
      _NavItem(icon: Icons.document_scanner_rounded, outlinedIcon: Icons.document_scanner_outlined, label: context.loc('my_cvs')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) {
        final List<Widget> pages = [
          HomeScreen(),
          AiCoachScreen(),
          JobListScreen(),
          CvListScreen(),
        ];
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: pages[_currentIndex],
          extendBody: true,
          bottomNavigationBar: _buildFloatingNavBar(context),
        );
      },
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    final navItems = _getNavItems(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B48FF).withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = _currentIndex == index;
            return _buildNavItem(item, index, isSelected);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.icon : item.outlinedIcon,
                color: isSelected ? AppTheme.primaryColor : const Color(0xFFB0B8C8),
                size: 22,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFFB0B8C8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(item.label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  const _NavItem({required this.icon, required this.outlinedIcon, required this.label});
}