import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String accent = 'material_you';
  static const String default_page = 'albums';

  bool _materialYou = true;
  bool _albums = true;

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool? savedMaterialYou = prefs.getBool(accent);
    final bool? savedAlbums = prefs.getBool(default_page);

    setState(() {
      if (savedMaterialYou != null) {
        _materialYou = savedMaterialYou;
      }

      if (savedAlbums != null) {
        _albums = savedAlbums;
      }
    });
  }

  void _saveSettings(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(key, value);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        scrollDirection: Axis.vertical,
        children: [
          Container(
            child: Row(
              children: [
                Text("Material You"),
                Switch(
                  value: _materialYou,
                  onChanged: (bool newValue) {
                    setState(() {
                      _materialYou = newValue;
                    });
                    _saveSettings(accent, newValue);
                  },
                ),
              ],
            ),
          ),

          Container(
            child: Row(
              children: [
                Text("Startup at Albums"),
                Switch(
                  value: _albums,
                  onChanged: (bool newValue) {
                    setState(() {
                      _albums = newValue;
                    });
                    _saveSettings(default_page, newValue);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
