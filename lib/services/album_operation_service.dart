import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/aves_entry.dart';
import 'media_service.dart';

class AlbumOperationService {
  static final AlbumOperationService _instance = AlbumOperationService._internal();
  factory AlbumOperationService() => _instance;
  AlbumOperationService._internal();

  final MediaService _mediaService = MediaService();

  Future<bool> requestPermission() async {
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

  /// Ensures a directory exists, creating it if necessary.
  Future<Directory?> createAlbumDirectory(String albumName) async {
    if (!await requestPermission()) {
      return null;
    }
    // We typically place new albums in the public Pictures directory.
    // For a robust implementation, we can just use /storage/emulated/0/Pictures
    final String picturesPath = '/storage/emulated/0/Pictures';
    Directory dir = Directory(path.join(picturesPath, albumName));
    
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        debugPrint('Error creating album directory: $e');
        return null;
      }
    }
    return dir;
  }

  Future<int> copyPhotos(List<AvesEntry> entries, Directory destination) async {
    return _transferPhotos(entries, destination, isMove: false);
  }

  Future<int> movePhotos(List<AvesEntry> entries, Directory destination) async {
    return _transferPhotos(entries, destination, isMove: true);
  }

  Future<int> _transferPhotos(List<AvesEntry> entries, Directory destination, {required bool isMove}) async {
    if (!await requestPermission()) return 0;

    int successCount = 0;
    const platform = MethodChannel('com.pixel.gallery/open_file');

    for (var entry in entries) {
      final originalFile = await entry.file;
      if (originalFile == null) continue;

      try {
        final String filename = path.basename(originalFile.path);
        // Avoid overwriting by checking if file exists
        String targetPath = path.join(destination.path, filename);
        int counter = 1;
        while (await File(targetPath).exists()) {
          final String ext = path.extension(filename);
          final String name = path.basenameWithoutExtension(filename);
          targetPath = path.join(destination.path, '\${name}_\$counter\$ext');
          counter++;
        }

        if (isMove) {
          // Attempt rename (move)
          try {
            await originalFile.rename(targetPath);
            // Tell MediaStore original file is gone
            await platform.invokeMethod('scanFile', {'path': originalFile.path});
            // Update app cache instantly
            await _mediaService.deleteEntry(entry);
          } catch (e) {
            // Rename fails across partitions, fallback to copy then delete
            await originalFile.copy(targetPath);
            await originalFile.delete();
            await platform.invokeMethod('scanFile', {'path': originalFile.path});
            await _mediaService.deleteEntry(entry);
          }
        } else {
          // Copy
          await originalFile.copy(targetPath);
        }

        // Tell MediaStore to scan new file
        await platform.invokeMethod('scanFile', {'path': targetPath});
        successCount++;
      } catch (e) {
        debugPrint('Error transferring photo: \$e');
      }
    }

    // Trigger full background sync to fetch the new entries and refresh albums structure
    if (successCount > 0) {
      _mediaService.clearCache();
      await _mediaService.triggerBackgroundSync();
    }

    return successCount;
  }
}
