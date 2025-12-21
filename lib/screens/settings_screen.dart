import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String accentKey = 'material_you';
  static const String defaultPageKey = 'albums';

  static Future<bool> getMaterialYou() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(accentKey) ?? true;
  }

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

  void _saveSettings(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == SettingsScreen.accentKey) _materialYou = value;
      if (key == SettingsScreen.defaultPageKey) _albums = value;
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
          Container(
            height: 50,
            margin: EdgeInsets.only(left: 15),
            child: Row(
              children: [
                Text("Material You"),
                Switch(
                  value: _materialYou,
                  onChanged: (bool val) =>
                      _saveSettings(SettingsScreen.accentKey, val),
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            margin: EdgeInsets.only(left: 15),
            child: Row(
              children: [
                Text("Startup at Albums"),
                Switch(
                  value: _albums,
                  onChanged: (bool val) =>
                      _saveSettings(SettingsScreen.defaultPageKey, val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
