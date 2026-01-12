import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String accentKey = 'material_you';
  static const String defaultPageKey = 'albums';
  static const String topEntryIdsKey = 'top_entry_ids';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Material You
  bool get materialYou => _prefs?.getBool(accentKey) ?? true;
  set materialYou(bool value) => _prefs?.setBool(accentKey, value);

  // Startup at Albums
  bool get startupAtAlbums => _prefs?.getBool(defaultPageKey) ?? false;
  set startupAtAlbums(bool value) => _prefs?.setBool(defaultPageKey, value);

  // Top Entry IDs (for Aves-style instant re-launch)
  List<int> get topEntryIds {
    final ids = _prefs?.getStringList(topEntryIdsKey);
    if (ids == null) return [];
    return ids.map((id) => int.tryParse(id)).whereType<int>().toList();
  }

  set topEntryIds(List<int> value) {
    _prefs?.setStringList(
      topEntryIdsKey,
      value.map((id) => id.toString()).toList(),
    );
  }
}
