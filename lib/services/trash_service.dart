import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/services/media_service.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class TrashItem {
  final String trashPath;
  final String originalPath;
  final int? dateDeletedMs;

  TrashItem({
    required this.trashPath,
    required this.originalPath,
    this.dateDeletedMs,
  });

  Map<String, dynamic> toJson() => {
    'trashPath': trashPath,
    'originalPath': originalPath,
    'dateDeletedMs': dateDeletedMs,
  };

  static TrashItem fromJson(Map<String, dynamic> json) {
    return TrashItem(
      trashPath: json['trashPath'] as String,
      originalPath: json['originalPath'] as String,
      dateDeletedMs: json['dateDeletedMs'] as int?,
    );
  }
}

class TrashService {
  // Singleton instance
  static final TrashService _instance = TrashService._internal();
  factory TrashService() => _instance;
  TrashService._internal();

  static const String _storageKey = 'trash_inventory';
  List<TrashItem> _trashedItems = [];
  Set<String> _trashedPathsSet = {};

  // Initializes the service by loading trashed paths from SharedPreferences.
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? storedList = prefs.getStringList(_storageKey);
    if (storedList != null) {
      _trashedItems = storedList
          .map((e) => TrashItem.fromJson(jsonDecode(e)))
          .toList();
      _updatedTrashedPathsSet();
    }

    // Validate inventory: remove items where trash file is missing
    final initialCount = _trashedItems.length;
    _trashedItems.removeWhere((item) => !File(item.trashPath).existsSync());
    if (initialCount != _trashedItems.length) {
      _updatedTrashedPathsSet();
    }
    await _saveInventory(prefs);
  }

  void _updatedTrashedPathsSet() {
    _trashedPathsSet = _trashedItems
        .expand((it) => [it.trashPath, it.originalPath])
        .toSet();
  }

  Future<void> _saveInventory([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    final List<String> encoded = _trashedItems
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  bool isTrashed(String? path) {
    if (path == null) return false;
    return _trashedPathsSet.contains(path);
  }

  List<String> get trashedPaths =>
      _trashedItems.map((e) => e.trashPath).toList();

  Future<bool>? _permissionFuture;

  // Request Manage External Storage Permission
  Future<bool> requestPermission() async {
    if (_permissionFuture != null) return _permissionFuture!;

    _permissionFuture = _performPermissionRequest();
    final result = await _permissionFuture!;
    _permissionFuture = null;
    return result;
  }

  Future<bool> _performPermissionRequest() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      }
    }
    // For older Android, standard storage permissions are usually enough
    return await Permission.storage.request().isGranted;
  }

  // Gets the designated hidden trash directory
  // We place it in the SAME partition root to ensure "rename" (move) works instantly.
  // E.g. /storage/emulated/0/.lumina_trash
  Future<Directory> _getTrashDirectoryFor(String originalPath) async {
    String rootPath = '/storage/emulated/0/';

    if (originalPath.startsWith('/storage/emulated/0/')) {
      rootPath = '/storage/emulated/0/';
    } else {
      // Try to find the root of the SD card if applicable
      // Simple heuristic: Take the first 3 segments ?
      // For now, default to internal storage root which covers 99% of cases
    }

    final Directory trashDir = Directory(path.join(rootPath, '.pixel_trash'));
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
    }
    return trashDir;
  }

  Future<void> moveToTrash(AvesEntry entry) async {
    // 1. Ensure permission
    if (!await requestPermission()) {
      debugPrint("Permission denied for Manage External Storage");
      return;
    }

    final File? originalFile = await entry.file;
    if (originalFile == null) return;

    final String originalPath = originalFile.path;
    debugPrint("Moving to trash: $originalPath");

    try {
      final Directory trashDir = await _getTrashDirectoryFor(originalPath);
      final String filename = path.basename(originalPath);

      // Create a unique name to avoid collisions in trash
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uniqueName = "${timestamp}_$filename";
      final String trashPath = path.join(trashDir.path, uniqueName);

      // 2. Perform the Move (Rename)
      // This is the key: rename() preserves metadata if on same partition
      final File file = File(originalPath);
      await file.rename(trashPath);

      // 3. Update Inventory
      _trashedItems.add(
        TrashItem(
          trashPath: trashPath,
          originalPath: originalPath,
          dateDeletedMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      _updatedTrashedPathsSet();
      await _saveInventory();

      // 4. Remove from local gallery index
      await MediaService().deleteEntry(entry);

      // 5. Tell MediaStore the file is gone/moved
      try {
        const platform = MethodChannel('com.pixel.gallery/open_file');
        await platform.invokeMethod('scanFile', {'path': originalPath});
        debugPrint("Native scan triggered for trashing: $originalPath");
      } catch (scanError) {
        debugPrint("Scan trigger error (trashing): $scanError");
      }

      debugPrint("Moved to trash successfully: $trashPath");
    } catch (e) {
      debugPrint("Error moving to trash: $e");
    }
  }

  Future<bool> restore(String trashPath) async {
    final int index = _trashedItems.indexWhere(
      (it) => it.trashPath == trashPath,
    );
    if (index == -1) return false;

    final TrashItem item = _trashedItems[index];
    final File trashFile = File(item.trashPath);

    if (!await trashFile.exists()) {
      _trashedItems.removeAt(index);
      await _saveInventory();
      return false;
    }

    try {
      // 1. Restore (Rename back)
      final File originalFile = File(item.originalPath);
      final Directory parentDir = originalFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await trashFile.rename(item.originalPath);
      debugPrint("File renamed back to: ${item.originalPath}");

      // 2. Trigger Scan (Partial)
      // Use a native scanFile call to inform MediaStore about the restored file.
      try {
        const platform = MethodChannel('com.pixel.gallery/open_file');
        await platform.invokeMethod('scanFile', {'path': item.originalPath});
        debugPrint("Native scan triggered for: ${item.originalPath}");
      } catch (scanError) {
        debugPrint(
          "Scan trigger error (might be ignored if file exists): $scanError",
        );
      }

      // 3. Update Inventory
      _trashedItems.removeAt(index);
      _updatedTrashedPathsSet();
      await _saveInventory();

      // 4. Notify Gallery Service to refresh
      MediaService().clearCache();
      MediaService().notifyAlbumUpdated();

      debugPrint("Restored successfully to: ${item.originalPath}");
      return true;
    } catch (e) {
      debugPrint("Error restoring: $e");
      return false;
    }
  }

  Future<void> deletePermanently(String trashPath) async {
    final File file = File(trashPath);
    if (await file.exists()) {
      await file.delete();
    }
    _trashedItems.removeWhere((it) => it.trashPath == trashPath);
    _updatedTrashedPathsSet();
    await _saveInventory();
  }
}
