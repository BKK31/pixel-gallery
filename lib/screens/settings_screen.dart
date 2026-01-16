import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lumina_gallery/screens/licenses_screen.dart';
import 'package:lumina_gallery/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChange;

  const SettingsScreen({super.key, this.onThemeChange});

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
        title: const Text(
          "Settings",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButtonM3E(
            icon: const Icon(FontAwesomeIcons.github),
            tooltip: "Source Code",
            onPressed: _openSourceCode,
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text(
              "Material You",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "Use dynamic colors from wallpaper",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            value: _materialYou,
            onChanged: (bool val) =>
                _saveSettings(SettingsService.accentKey, val),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(height: 1),
          SwitchListTile(
            title: const Text(
              "Startup at Albums",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "Start on Albums page instead of Photos",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            value: _albums,
            onChanged: (bool val) =>
                _saveSettings(SettingsService.defaultPageKey, val),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(height: 1),
          ListTile(
            title: const Text(
              "Open Source Licenses",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "Credits and license information",
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
        ],
      ),
    );
  }
}
