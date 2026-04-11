import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lumina_gallery/screens/licenses_screen.dart';
import 'package:lumina_gallery/screens/excluded_folders_screen.dart';
import 'package:lumina_gallery/services/settings_service.dart';
import 'package:lumina_gallery/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChange;
  final VoidCallback? onLanguageChange;

  const SettingsScreen({
    super.key,
    this.onThemeChange,
    this.onLanguageChange,
  });

  static const String accentKey = SettingsService.accentKey;
  static const String defaultPageKey = SettingsService.defaultPageKey;

  // Reads the 'Material You' preference (Synchronous via Service).
  static bool getMaterialYou() => SettingsService().materialYou;

  // Reads the 'Startup at Albums' preference (Synchronous via Service).
  static bool getStartupAtAlbums() => SettingsService().startupAtAlbums;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _materialYou;
  late bool _albums;

  @override
  void initState() {
    super.initState();
    _materialYou = SettingsService().materialYou;
    _albums = SettingsService().startupAtAlbums;
  }

  String _getLanguageName(String? code, BuildContext context) {
    if (code == null) return AppLocalizations.of(context)!.languageSystemDefault;
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'हिन्दी (Hindi)',
      'kn': 'ಕನ್ನಡ (Kannada)',
      'es': 'Español (Spanish)',
      'fr': 'Français (French)',
      'de': 'Deutsch (German)',
      'pt': 'Português (Portuguese)',
      'ru': 'Русский (Russian)',
      'zh': '中文 (Chinese)',
      'ja': '日本語 (Japanese)',
      'ar': 'العربية (Arabic)',
      'it': 'Italiano (Italian)',
    };
    return languages[code] ?? code;
  }

  void _showLanguageDialog() {
    final currentCode = SettingsService().languageCode;
    final Map<String?, String> languageOptions = {
      null: AppLocalizations.of(context)!.languageSystemDefault,
      'en': 'English',
      'hi': 'हिन्दी',
      'kn': 'ಕನ್ನಡ',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ar': 'العربية',
      'it': 'Italiano',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settingsLanguage),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: languageOptions.entries.map((entry) {
              return RadioListTile<String?>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: currentCode,
                onChanged: (val) {
                  SettingsService().languageCode = val;
                  Navigator.pop(context);
                  widget.onLanguageChange?.call();
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Saves a boolean preference setting and updates local state.
  void _saveSettings(String key, bool value) {
    final settings = SettingsService();
    setState(() {
      if (key == SettingsScreen.accentKey) {
        settings.materialYou = value;
        _materialYou = value;
        widget.onThemeChange?.call();
      }
      if (key == SettingsScreen.defaultPageKey) {
        settings.startupAtAlbums = value;
        _albums = value;
      }
    });
  }

  Future<void> _openSourceCode() async {
    const url = 'https://github.com/bkk31/pixel-gallery';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarM3E(
        title: Text(
          AppLocalizations.of(context)!.settingsTitle,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButtonM3E(
            icon: const Icon(FontAwesomeIcons.github),
            tooltip: AppLocalizations.of(context)!.settingsSourceCode,
            onPressed: _openSourceCode,
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              AppLocalizations.of(context)!.settingsMaterialYou,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.settingsMaterialYouDesc,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            value: _materialYou,
            onChanged: (bool val) =>
                _saveSettings(SettingsService.accentKey, val),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(height: 1),
          SwitchListTile(
            title: Text(
              AppLocalizations.of(context)!.settingsStartupAlbums,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.settingsStartupAlbumsDesc,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            value: _albums,
            onChanged: (bool val) =>
                _saveSettings(SettingsService.defaultPageKey, val),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(height: 1),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.settingsExcludedFolders,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.settingsExcludedFoldersDesc,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExcludedFoldersScreen(),
                ),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.settingsLicenses,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.settingsLicensesDesc,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LicensesScreen()),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.settingsLanguage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _getLanguageName(SettingsService().languageCode, context),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.language),
            onTap: _showLanguageDialog,
          ),
          Divider(height: 1),
        ],
      ),
    );
  }
}
