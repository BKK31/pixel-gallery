import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/aves_entry.dart';
import 'media_service.dart';

/// A vault item tracks the moved file and the original entry metadata
/// so we can display thumbnails and restore the file later.
class VaultItem {
  final String vaultPath;
  final String originalPath;
  final Map<String, dynamic> entryMap; // serialised AvesEntry

  VaultItem({
    required this.vaultPath,
    required this.originalPath,
    required this.entryMap,
  });

  Map<String, dynamic> toJson() => {
    'vaultPath': vaultPath,
    'originalPath': originalPath,
    'entryMap': entryMap,
  };

  static VaultItem fromJson(Map<String, dynamic> json) {
    return VaultItem(
      vaultPath: json['vaultPath'] as String,
      originalPath: json['originalPath'] as String,
      entryMap: Map<String, dynamic>.from(json['entryMap'] as Map),
    );
  }

  AvesEntry toAvesEntry() {
    // Override the path with the vault path so thumbnails and files resolve
    final map = Map<String, dynamic>.from(entryMap);
    map['path'] = vaultPath;
    return AvesEntry.fromMap(map);
  }
}

/// Manages the locked folder vault.
/// Files are physically moved to the app's private directory and
/// obfuscated (UUID filename, no extension). They are completely
/// invisible to the system media scanner and other apps.
class LockedFolderService {
  static final LockedFolderService _instance = LockedFolderService._internal();
  factory LockedFolderService() => _instance;
  LockedFolderService._internal();

  static const String _storageKey = 'vault_inventory';

  SharedPreferences? _prefs;
  List<VaultItem> _vaultItems = [];

  /// Set of content IDs currently in the vault (for fast O(1) filtering).
  Set<int> _lockedIds = {};

  /// Must be called once during app start-up.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _loadInventory();
  }

  void _loadInventory() {
    final list = _prefs?.getStringList(_storageKey);
    if (list == null) {
      _vaultItems = [];
      _lockedIds = {};
      return;
    }
    _vaultItems = list
        .map((e) => VaultItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    _rebuildLockedIds();
  }

  void _rebuildLockedIds() {
    _lockedIds = _vaultItems
        .map((v) => v.entryMap['contentId'] as int?)
        .whereType<int>()
        .toSet();
  }

  Future<void> _saveInventory() async {
    final encoded = _vaultItems.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs?.setStringList(_storageKey, encoded);
  }

  /// The set of content IDs in the vault – used by MediaService for filtering.
  Set<int> get lockedIds => _lockedIds;

  /// Whether a given content ID is locked.
  bool isLocked(int? contentId) {
    if (contentId == null) return false;
    return _lockedIds.contains(contentId);
  }

  /// Get the vault directory (inside natively isolated app-specific external storage).
  Future<Directory> _getVaultDir() async {
    // getExternalStorageDirectory() resolves to /storage/emulated/0/Android/data/com.pixel.gallery/files
    final appDataDir = await getExternalStorageDirectory();
    if (appDataDir == null) {
      throw Exception('Could not access Android/data storage');
    }
    // Use the parent to get /storage/emulated/0/Android/data/com.pixel.gallery/vault
    final vaultDir = Directory(p.join(appDataDir.parent.path, 'vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    // Create .nomedia file to ensure the vault is hidden from other gallery apps
    final noMediaFile = File(p.join(vaultDir.path, '.nomedia'));
    if (!await noMediaFile.exists()) {
      await noMediaFile.create();
    }
    
    return vaultDir;
  }

  // ---------------------------------------------------------------
  // Permission helper (same pattern as TrashService)
  // ---------------------------------------------------------------
  Future<bool>? _permissionFuture;

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
    return await Permission.storage.request().isGranted;
  }

  // ---------------------------------------------------------------
  // Lock / Unlock
  // ---------------------------------------------------------------

  /// Move an entry's file into the vault. Returns true on success.
  Future<bool> lock(AvesEntry entry) async {
    if (entry.contentId == null || entry.path == null) return false;

    // Ensure storage permission
    if (!await requestPermission()) {
      debugPrint('LockedFolderService: storage permission denied');
      return false;
    }

    final File originalFile = File(entry.path!);
    if (!await originalFile.exists()) {
      debugPrint('LockedFolderService: original file does not exist');
      return false;
    }

    try {
      final vaultDir = await _getVaultDir();

      // Ensure exact original extension is preserved for media_kit / glide decoders.
      // Append contentId to prevent name collisions if lock targets have identical filenames from multiple directories.
      final String originalFilename = p.basename(entry.path!);
      final vaultFileName = '${entry.contentId}_$originalFilename';
      final vaultPath = p.join(vaultDir.path, vaultFileName);

      // Atomic rename for perfection on same partition (Android/data is on /storage/emulated/0)
      try {
        await originalFile.rename(vaultPath);
      } catch (e) {
        // Fallback for cross-partition (e.g. from an actual SD card)
        await originalFile.copy(vaultPath);
        await originalFile.delete();
      }

      // Store inventory item with full entry metadata for later display
      _vaultItems.add(
        VaultItem(
          vaultPath: vaultPath,
          originalPath: entry.path!,
          entryMap: entry.toMap(),
        ),
      );
      _rebuildLockedIds();
      await _saveInventory();

      // Remove from gallery index & notify MediaStore
      await MediaService().deleteEntry(entry);
      _scanFile(entry.path!);

      debugPrint('LockedFolderService: locked ${entry.path} -> $vaultPath');
      return true;
    } catch (e) {
      debugPrint('LockedFolderService: error locking: $e');
      return false;
    }
  }

  /// Restore an entry from the vault back to its original location.
  /// Returns true on success.
  Future<bool> unlock(AvesEntry entry) async {
    final contentId = entry.contentId;
    if (contentId == null) return false;

    final index = _vaultItems.indexWhere(
      (v) => v.entryMap['contentId'] == contentId,
    );
    if (index == -1) return false;

    // Ensure storage permission
    if (!await requestPermission()) return false;

    final item = _vaultItems[index];
    final vaultFile = File(item.vaultPath);

    if (!await vaultFile.exists()) {
      // File is gone – clean up inventory
      _vaultItems.removeAt(index);
      _rebuildLockedIds();
      await _saveInventory();
      return false;
    }

    try {
      // Ensure original parent directory exists
      final parentDir = Directory(p.dirname(item.originalPath));
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // Native Android/data is unaffected by MediaScanner, meaning the file
      // simply resided in a separate directory natively unmodified.
      // Rename back to original path securely
      try {
        await vaultFile.rename(item.originalPath);
      } catch (e) {
        await vaultFile.copy(item.originalPath);
        await vaultFile.delete();
      }

      // Restore modification time on disk so the MediaScanner picks it up correctly
      final dateModifiedMillis = item.entryMap['dateModifiedMillis'] as int?;
      if (dateModifiedMillis != null) {
        try {
          await File(item.originalPath).setLastModified(
            DateTime.fromMillisecondsSinceEpoch(dateModifiedMillis),
          );
        } catch (e) {
          debugPrint('LockedFolderService: error restoring lastModified on disk: $e');
        }
      }

      // Update inventory
      _vaultItems.removeAt(index);
      _rebuildLockedIds();
      await _saveInventory();

      // Trigger standard MediaStore indexing but FORCE native database timestamp updates
      _scanFile(
        item.originalPath,
        dateAddedSecs: item.entryMap['dateAddedSecs'] as int?,
        dateModifiedSecs: (item.entryMap['dateModifiedMillis'] as int?) != null 
            ? (item.entryMap['dateModifiedMillis'] as int) ~/ 1000 
            : null,
        dateTakenMillis: item.entryMap['sourceDateTakenMillis'] as int?,
      );

      // Refresh gallery
      MediaService().clearCache();
      MediaService().notifyAlbumUpdated();

      debugPrint(
        'LockedFolderService: unlocked ${item.vaultPath} -> ${item.originalPath}',
      );
      return true;
    } catch (e) {
      debugPrint('LockedFolderService: error unlocking: $e');
      return false;
    }
  }

  /// Unlock multiple entries.
  Future<void> unlockAll(List<AvesEntry> entries) async {
    for (final entry in entries) {
      await unlock(entry);
    }
  }

  /// Returns AvesEntry objects for every vaulted file (with path pointing
  /// to the vault copy so thumbnails load correctly).
  List<AvesEntry> getLockedEntries() {
    return _vaultItems.map((v) => v.toAvesEntry()).toList();
  }

  /// Trigger a native MediaStore scan on the given path with optional metadata overrides.
  void _scanFile(String filePath, {int? dateAddedSecs, int? dateModifiedSecs, int? dateTakenMillis}) {
    try {
      const platform = MethodChannel('com.pixel.gallery/open_file');
      platform.invokeMethod('scanFile', {
        'path': filePath,
        if (dateAddedSecs != null) 'dateAddedSecs': dateAddedSecs,
        if (dateModifiedSecs != null) 'dateModifiedSecs': dateModifiedSecs,
        if (dateTakenMillis != null) 'dateTakenMillis': dateTakenMillis,
      });
    } catch (e) {
      debugPrint('LockedFolderService: scanFile error: $e');
    }
  }
}
