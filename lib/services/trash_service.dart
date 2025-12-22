import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TrashService {
  static const String _key = 'trash_paths';

  List<String> _trashedPaths = [];

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedPaths = prefs.getStringList(_key) ?? [];
  }

  bool isTrashed(String id) {
    return _trashedPaths.contains(id);
  }

  Future<void> moveToTrash(AssetEntity asset) async {
    final File? originalFile = await asset.file;
    if (originalFile == null) return;

    try {
      // 1. Get Private 'trash' directory
      final appDir = await getApplicationDocumentsDirectory();
      final trashDir = Directory('${appDir.path}/trash');
      if (!await trashDir.exists()) {
        await trashDir.create(recursive: true);
      }

      // 2. Copy file to private trash
      final String filename = path.basename(originalFile.path);
      final String newPath = path.join(trashDir.path, filename);

      // Copy to private dir
      await originalFile.copy(newPath);

      // 3. Delete original from Gallery (triggers system perm dialog)
      final List<String> result = await PhotoManager.editor.deleteWithIds([
        asset.id,
      ]);

      // 4. If deletion successful, verify and track
      if (result.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _trashedPaths.add(newPath);
        await prefs.setStringList(_key, _trashedPaths);
      } else {
        // If user cancelled, delete our backup
        final backupFile = File(newPath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      }
    } catch (e) {
      print("Error moving to trash: $e");
    }
  }

  Future<void> restore(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) return;

    try {
      final String name = path.basename(filePath);
      // Determine if image or video based on extension (simple check)
      final bool isVideo =
          name.toLowerCase().endsWith('.mp4') ||
          name.toLowerCase().endsWith('.mov') ||
          name.toLowerCase().endsWith('.wmv') ||
          name.toLowerCase().endsWith('.avi') ||
          name.toLowerCase().endsWith('.mkv');

      AssetEntity? restoredAsset;
      if (isVideo) {
        restoredAsset = await PhotoManager.editor.saveVideo(file, title: name);
      } else {
        // Assume image
        restoredAsset = await PhotoManager.editor.saveImageWithPath(
          filePath,
          title: name,
        );
      }

      if (restoredAsset != null) {
        // Remove local backup
        await file.delete();

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _trashedPaths.remove(filePath);
        await prefs.setStringList(_key, _trashedPaths);
      }
    } catch (e) {
      print("Error restoring: $e");
    }
  }

  Future<void> deletePermanently(String filePath) async {
    final File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedPaths.remove(filePath);
    await prefs.setStringList(_key, _trashedPaths);
  }

  List<String> get trashedPaths => _trashedPaths;
}
