import 'package:shared_preferences/shared_preferences.dart';
import '../models/filters.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String accentKey = 'material_you';
  static const String defaultPageKey = 'albums';
  static const String topEntryIdsKey = 'top_entry_ids';
  static const String hiddenAlbumsKey = 'hidden_albums';
  static const String hiddenFiltersKey = 'hidden_filters';
  static const String languageKey = 'language_code';

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

  // Hidden Albums
  Set<String> get hiddenAlbums {
    final list = _prefs?.getStringList(hiddenAlbumsKey);
    if (list == null) return {};
    return list.toSet();
  }

  Future<void> setHiddenAlbums(Set<String> value) async {
    await _prefs?.setStringList(hiddenAlbumsKey, value.toList());
  }

  // Hidden Filters
  Set<GalleryFilter> get hiddenFilters {
    final list = _prefs?.getStringList(hiddenFiltersKey);
    if (list == null) return {};
    return list.map((jsonStr) {
      try {
        return GalleryFilter.fromJson(jsonStr);
      } catch (e) {
        return null;
      }
    }).whereType<GalleryFilter>().toSet();
  }

  Future<void> setHiddenFilters(Set<GalleryFilter> value) async {
    await _prefs?.setStringList(hiddenFiltersKey, value.map((f) => f.toJson()).toList());
  }

  // Language
  String? get languageCode => _prefs?.getString(languageKey);
  set languageCode(String? value) {
    if (value == null) {
      _prefs?.remove(languageKey);
    } else {
      _prefs?.setString(languageKey, value);
    }
  }
}
