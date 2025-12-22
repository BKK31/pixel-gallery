import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChange;

  const SettingsScreen({super.key, this.onThemeChange});

  static const String accentKey = 'material_you';
  static const String defaultPageKey = 'albums';

  // Reads the 'Material You' preference (default: true).
  static Future<bool> getMaterialYou() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(accentKey) ?? true;
  }

  // Reads the 'Startup at Albums' preference (default: true).
  static Future<bool> getStartupAtAlbums() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(defaultPageKey) ?? true;
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _materialYou = true;
  bool _albums = true;

  @override
  void initState() {
    super.initState();
    _refreshSettings();
  }

  Future<void> _refreshSettings() async {
    bool mYou = await SettingsScreen.getMaterialYou();
    bool sAlbums = await SettingsScreen.getStartupAtAlbums();
    setState(() {
      _materialYou = mYou;
      _albums = sAlbums;
    });
  }

  // Saves a boolean preference setting and updates local state.
  // Triggers the onThemeChange callback if the theme setting is toggled.
  Future<void> _saveSettings(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    setState(() {
      if (key == SettingsScreen.accentKey) {
        _materialYou = value;
        // Notify parent that theme changed
        widget.onThemeChange?.call();
      }
      if (key == SettingsScreen.defaultPageKey) {
        _albums = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              "Material You",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "Use dynamic colors from wallpaper",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            value: _materialYou,
            onChanged: (bool val) =>
                _saveSettings(SettingsScreen.accentKey, val),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(height: 1),
          SwitchListTile(
            title: Text(
              "Startup at Albums",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "Start on Albums page instead of Photos",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            value: _albums,
            onChanged: (bool val) =>
                _saveSettings(SettingsScreen.defaultPageKey, val),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(height: 1),
        ],
      ),
    );
  }
}
