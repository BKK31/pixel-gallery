import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_exif/native_exif.dart';
import '../models/aves_entry.dart';
import 'local_db.dart';
import 'notification_service.dart';
import 'media_service.dart';
import 'media_fetch_service.dart';
import 'dart:async';

class CatalogService {
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  final LocalDatabase _db = LocalDatabase();
  final NotificationService _notifications = NotificationService();
  final MediaFetchService _mediaFetchService = mediaFetchService;

  static const _platform = MethodChannel('com.pixel.gallery/open_file');

  bool _isCataloging = false;
  bool get isCataloging => _isCataloging;

  Future<void> startCataloging() async {
    if (_isCataloging) return;
    _isCataloging = true;

    try {
      final uncatalogued = await _db.getUncataloguedEntries();
      if (uncatalogued.isEmpty) return;

      int total = uncatalogued.length;
      int current = 0;

      for (final entry in uncatalogued) {
        if (!_isCataloging) break;

        final path = entry.path;
        final contentId = entry.contentId;
        if (path != null && contentId != null) {
          try {
            // Extract metadata
            final metadata = await _extractMetadata(entry);

            await _db.saveMetadata(contentId, metadata);

            // Pre-generate thumbnail for instant loading
            // Now using ServicePolicy via mediaFetchService
            try {
              await _mediaFetchService.getThumbnail(
                entry: entry,
                extent: 200.0,
              );
            } catch (e) {
              // Don't fail cataloging if thumbnail fails
            }

            // Only notify UI occasionally to avoid flooding
            if (current % 5 == 0) {
              MediaService().notifyEntryUpdated(entry);
            }
          } catch (e) {
            // Still mark as catalogued even if extraction fails
            await _db.saveMetadata(contentId, {
              'latitude': null,
              'longitude': null,
              'xmpSubjects': null,
              'xmpTitle': null,
              'rating': null,
            });
          }
        }

        current++;
        // Update notification progress less frequently
        if (current % 20 == 0 || current == total) {
          await _notifications.showCatalogingProgress(current, total);
        }

        // Yield to allow other events to process
        await Future.delayed(Duration.zero);
      }
    } finally {
      _isCataloging = false;
      await _notifications.dismissCatalogingProgress();
    }
  }

  Future<Map<String, dynamic>> _extractMetadata(AvesEntry entry) async {
    final path = entry.path;
    if (path == null) return {};

    if (entry.isVideo) {
      return await _extractVideoMetadata(path);
    } else {
      return await _extractPhotoMetadata(path);
    }
  }

  Future<Map<String, dynamic>> _extractPhotoMetadata(String path) async {
    try {
      final exif = await Exif.fromPath(path);
      final latLong = await exif.getLatLong();
      final attributes = await exif.getAttributes();

      // Native HDR detection
      bool isHdr = false;
      try {
        isHdr = await _platform.invokeMethod('checkImageHdr', {'path': path});
      } catch (e) {
        debugPrint("Error checking native HDR: $e");
      }

      final metadata = {
        'latitude': latLong?.latitude,
        'longitude': latLong?.longitude,
        'make': attributes?['Make'],
        'model': attributes?['Model'],
        'xmpSubjects': null,
        'xmpTitle': null,
        'rating': null,
        'isHdr': isHdr,
      };
      await exif.close();
      return metadata;
    } catch (e) {
      return {
        'latitude': null,
        'longitude': null,
        'make': null,
        'model': null,
        'xmpSubjects': null,
        'xmpTitle': null,
        'rating': null,
        'isHdr': false,
      };
    }
  }

  Future<Map<String, dynamic>> _extractVideoMetadata(String path) async {
    try {
      final Map? result = await _platform.invokeMethod('getVideoMetadata', {
        'path': path,
      });
      if (result == null) throw Exception('No metadata returned');

      double? latitude;
      double? longitude;

      final String? location = result['location'] as String?;
      if (location != null) {
        // ISO 6709 format: +27.5916+086.5640/ or +27.5916-086.5640/
        final regex = RegExp(r'([+-]\d+\.\d+)([+-]\d+\.\d+)');
        final match = regex.firstMatch(location);
        if (match != null) {
          latitude = double.tryParse(match.group(1)!);
          longitude = double.tryParse(match.group(2)!);
        }
      }

      return {
        'latitude': latitude,
        'longitude': longitude,
        'make': result['make'],
        'model': result['model'],
        'xmpSubjects': null,
        'xmpTitle': null,
        'rating': null,
      };
    } catch (e) {
      debugPrint('Error extracting video metadata: $e');
      return {
        'latitude': null,
        'longitude': null,
        'make': null,
        'model': null,
        'xmpSubjects': null,
        'xmpTitle': null,
        'rating': null,
      };
    }
  }

  void stopCataloging() {
    _isCataloging = false;
  }
}
