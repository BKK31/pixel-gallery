import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';

class TrashService {
  static const String _key = 'trash_id';

  List<String> _trashedIds = [];

  Future<void> init() async {
    // Initialize SharedPreferences and load the list of trashed asset IDs
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedIds = prefs.getStringList(_key) ?? [];
  }

  bool isTrashed(String id) {
    // Check if an asset ID is present in the trashed list
    return _trashedIds.contains(id);
  }

  Future<void> moveToTrash(String id) async {
    // Add an asset ID to the trash list and persist it
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedIds.add(id);
    await prefs.setStringList(_key, _trashedIds);
  }

  Future<void> restore(String id) async {
    // Remove an asset ID from the trash list and update storage
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedIds.remove(id);
    await prefs.setStringList(_key, _trashedIds);
  }

  Future<void> deletePermanently(String id) async {
    // Permanently delete the asset using PhotoManager and remove it from the local trash list
    await PhotoManager.editor.deleteWithIds([id]);
    await restore(id);
  }

  List<String> get trashedIds => _trashedIds;
}
