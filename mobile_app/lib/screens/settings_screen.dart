import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/settings_service.dart';
import '../services/localization_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              context.loc('settings'),
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context.loc('theme_appearance')),
                const SizedBox(height: 12),
                _buildThemeSelector(),
                const SizedBox(height: 32),
                _buildSectionHeader(context.loc('language_options')),
                const SizedBox(height: 12),
                _buildLanguageSelector(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildRadioTile<ThemeMode>(
            title: context.loc('light_theme'),
            icon: Icons.light_mode_outlined,
            value: ThemeMode.light,
            groupValue: settingsService.themeMode,
            onChanged: (val) {
              if (val != null) settingsService.updateThemeMode(val);
              setState(() {});
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildRadioTile<ThemeMode>(
            title: context.loc('dark_theme'),
            icon: Icons.dark_mode_outlined,
            value: ThemeMode.dark,
            groupValue: settingsService.themeMode,
            onChanged: (val) {
              if (val != null) settingsService.updateThemeMode(val);
              setState(() {});
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildRadioTile<ThemeMode>(
            title: context.loc('system_theme'),
            icon: Icons.settings_system_daydream_outlined,
            value: ThemeMode.system,
            groupValue: settingsService.themeMode,
            onChanged: (val) {
              if (val != null) settingsService.updateThemeMode(val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildRadioTile<String>(
            title: context.loc('lang_tr'),
            icon: Icons.language_outlined,
            value: "tr",
            groupValue: settingsService.languageCode,
            onChanged: (val) {
              if (val != null) settingsService.updateLanguage(val);
              setState(() {});
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildRadioTile<String>(
            title: context.loc('lang_en'),
            icon: Icons.language_outlined,
            value: "en",
            groupValue: settingsService.languageCode,
            onChanged: (val) {
              if (val != null) settingsService.updateLanguage(val);
              setState(() {});
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildRadioTile<String>(
            title: context.loc('lang_de'),
            icon: Icons.language_outlined,
            value: "de",
            groupValue: settingsService.languageCode,
            onChanged: (val) {
              if (val != null) settingsService.updateLanguage(val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required IconData icon,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: RadioListTile<T>(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
