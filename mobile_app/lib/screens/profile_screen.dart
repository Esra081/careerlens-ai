import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/localization_service.dart';

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

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('profile'), style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      selectedColor: primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? primaryColor 
                            : (isDarkMode ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
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
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
