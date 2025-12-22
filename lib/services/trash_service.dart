import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Service responsible for handling moved-to-trash assets.
// Instead of a "dot-file" approach, this service copies files to a private
// app directory ('trash') and then deletes them from the system gallery.
// It maintains a list of trashed file paths in SharedPreferences to support restoration.
class TrashService {
  static const String _key = 'trash_paths';

  List<String> _trashedPaths = [];

  // Initializes the service by loading trashed paths from SharedPreferences.
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _trashedPaths = prefs.getStringList(_key) ?? [];
  }

  // Checks if a given asset ID (or path in some contexts) is currently in the trash.
  // Note: This implementation currently checks against stored paths.
  bool isTrashed(String id) {
    return _trashedPaths.contains(id);
  }

  // Moves an asset to the internal trash directory and deletes it from the device gallery.
  // Steps:
  // 1. Copy the original file to specific private 'trash' directory.
  // 2. Request system deletion of the original asset.
  // 3. If successful, save the new path to SharedPreferences.
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

  // Restores a file from the trash back to the device gallery.
  // Steps:
  // 1. Identifies if the file is an image or video.
  // 2. Uses PhotoManager to save it back to the public gallery.
  // 3. Deletes the private backup file and updates SharedPreferences.
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

  // Permanently deletes a file from the trash (private storage).
  // This action is irreversible.
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
