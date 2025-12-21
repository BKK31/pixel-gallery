import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';

class TrashService {
  static const String _key = 'trash_id';

  List<String> _trashedIds = [];

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedIds = prefs.getStringList(_key) ?? [];
  }

  bool isTrashed(String id) {
    return _trashedIds.contains(id);
  }

  Future<void> moveToTrash(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedIds.add(id);
    await prefs.setStringList(_key, _trashedIds);
  }

  Future<void> restore(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedIds.remove(id);
    await prefs.setStringList(_key, _trashedIds);
  }

  Future<void> deletePermanently(String id) async {
    await PhotoManager.editor.deleteWithIds([id]);
    await restore(id);
  }

  List<String> get trashedIds => _trashedIds;
}
