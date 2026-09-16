import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _skillController = TextEditingController();

  void _addSkill(BuildContext context) {
    final skill = _skillController.text;
    if (skill.isNotEmpty) {
      context.read<UserProvider>().addSkill(skill);
      _skillController.clear();
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text("Çıkış Yap"),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('profile'), style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Çıkış Yap',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı Profil Kartı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          (user?.fullName.isNotEmpty == true ? user!.fullName[0] : "E").toUpperCase(),
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? "Esra Kılıç",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? "esra@example.com",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  context.loc('experience_level'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: ['junior', 'mid', 'senior'].map((levelKey) {
                    // Match with the provider value which might be 'Junior', 'Mid', 'Senior'
                    final providerLevel = levelKey == 'junior' ? 'Junior' : (levelKey == 'mid' ? 'Mid' : 'Senior');
                    final isSelected = userProvider.experienceLevel == providerLevel;
                    return ChoiceChip(
                      label: Text(context.loc(levelKey)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          userProvider.setExperienceLevel(providerLevel);
                        }
                      },
                      selectedColor: primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? primaryColor 
                            : (isDarkMode ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Text(
                  context.loc('tech_stack'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _skillController,
                  decoration: InputDecoration(
                    hintText: context.loc('add_skill_hint'),
                    prefixIcon: const Icon(Icons.code),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: primaryColor,
                      onPressed: () => _addSkill(context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _addSkill(context),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: userProvider.skills.map((skill) {
                    return InputChip(
                      label: Text(skill),
                      onDeleted: () => userProvider.removeSkill(skill),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      deleteIconColor: Colors.redAccent,
                      backgroundColor: isDarkMode 
                          ? Colors.grey[850] 
                          : Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

}
