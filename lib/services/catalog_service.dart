import 'package:native_exif/native_exif.dart';
import '../models/aves_entry.dart';
import 'local_db.dart';
import 'notification_service.dart';
import 'media_service.dart';

class CatalogService {
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  final LocalDatabase _db = LocalDatabase();
  final NotificationService _notifications = NotificationService();

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
        if (path != null) {
          try {
            final exif = await Exif.fromPath(path);
            final latLong = await exif.getLatLong();

            final updatedEntry = AvesEntry(
              uri: entry.uri,
              path: entry.path,
              sourceMimeType: entry.sourceMimeType,
              width: entry.width,
              height: entry.height,
              sourceRotationDegrees: entry.sourceRotationDegrees,
              sizeBytes: entry.sizeBytes,
              dateAddedSecs: entry.dateAddedSecs,
              dateModifiedMillis: entry.dateModifiedMillis,
              sourceDateTakenMillis: entry.sourceDateTakenMillis,
              durationMillis: entry.durationMillis,
              contentId: entry.contentId,
              latitude: latLong?.latitude,
              longitude: latLong?.longitude,
              isCatalogued: true,
            );

            await _db.updateEntry(updatedEntry);
            MediaService().notifyEntryUpdated(updatedEntry);
            await exif.close();
          } catch (e) {
            // If failed, still mark as catalogued to avoid retrying indefinitely
            final failedEntry = AvesEntry(
              uri: entry.uri,
              path: entry.path,
              sourceMimeType: entry.sourceMimeType,
              width: entry.width,
              height: entry.height,
              sourceRotationDegrees: entry.sourceRotationDegrees,
              sizeBytes: entry.sizeBytes,
              dateAddedSecs: entry.dateAddedSecs,
              dateModifiedMillis: entry.dateModifiedMillis,
              sourceDateTakenMillis: entry.sourceDateTakenMillis,
              durationMillis: entry.durationMillis,
              contentId: entry.contentId,
              isCatalogued: true,
            );
            await _db.updateEntry(failedEntry);
          }
        }

        current++;
        if (current % 10 == 0 || current == total) {
          await _notifications.showCatalogingProgress(current, total);
        }
      }
    } finally {
      _isCataloging = false;
      await _notifications.dismissCatalogingProgress();
    }
  }

  void stopCataloging() {
    _isCataloging = false;
  }
}
