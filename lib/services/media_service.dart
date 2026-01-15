import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:async';

import '../models/photo_model.dart';
import '../models/aves_entry.dart';
import '../models/album_model.dart';
import 'media_store_service.dart';
import 'local_db.dart';
import 'notification_service.dart';
import 'catalog_service.dart';
import 'trash_service.dart';
import 'settings_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'favourites_manager.dart';

// Service responsible for fetching and managing media assets (photos/videos)
// and albums using Aves MediaStore engine.
class MediaService {
  // Singleton instance
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final MediaStoreService _service = PlatformMediaStoreService();
  final LocalDatabase _db = LocalDatabase();
  final NotificationService _notifications = NotificationService();
  final CatalogService _catalog = CatalogService();
  final TrashService _trashService = TrashService();

  // Stream for notifying UI about entry updates (e.g. after cataloging)
  final StreamController<AvesEntry> _entryUpdateController =
      StreamController<AvesEntry>.broadcast();
  Stream<AvesEntry> get entryUpdateStream => _entryUpdateController.stream;

  final StreamController<int> _entryDeletedController =
      StreamController<int>.broadcast();
  Stream<int> get entryDeletedStream => _entryDeletedController.stream;

  final StreamController<void> _albumUpdateController =
      StreamController<void>.broadcast();
  Stream<void> get albumUpdateStream => _albumUpdateController.stream;

  // Cache for albums to provide instant access
  List<AlbumModel>? _cachedAlbums;
  List<AvesEntry> _allEntries = [];
  bool _isInitialized = false;

  // Clears the internal cache, useful when gallery changes are detected.
  void clearCache() {
    _cachedAlbums = null;
  }

  // Cache the permission future to handle concurrent requests
  Future<bool>? _permissionFuture;

  // Requests permissions to access the device's photo library.
  // Returns true if access is granted.
  Future<bool> requestPermission() async {
    if (_permissionFuture != null) return _permissionFuture!;

    _permissionFuture = _performPermissionRequest();
    final result = await _permissionFuture!;

    // Clean up after result is obtained so it can be re-queried if needed later
    // but keep it long enough to catch simultaneous calls.
    _permissionFuture = null;
    return result;
  }

  Future<bool> _performPermissionRequest() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        final statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.notification,
        ].request();
        return statuses.values.every((status) => status.isGranted);
      } else {
        final statuses = await [
          Permission.storage,
          Permission.notification,
        ].request();
        return statuses.values.every((status) => status.isGranted);
      }
    }
    return false;
  }

  // Fetches all media entries and groups them into albums.
  Future<List<AlbumModel>> _fetchAllMediaAndGroup() async {
    final entries = <AvesEntry>[];
    await for (final entry in getMediaStream()) {
      entries.add(entry);
    }
    return _groupEntries(entries);
  }

  // Helper to group entries into albums. Improved for performance with large libraries.
  List<AlbumModel> _groupEntries(List<AvesEntry> entries) {
    // 1. Filter out entries in trash using O(1) set lookup
    final filteredEntries = entries
        .where((entry) => !_trashService.isTrashed(entry.path))
        .toList();

    // Since entries from DB are already sorted by dateModifiedMillis DESC,
    // we take advantage of that for the "Recent" album.
    final albums = <AlbumModel>[];

    // Create "Recent" album
    albums.add(
      AlbumModel(
        id: 'recent',
        name: 'Recent',
        entries: filteredEntries,
        isAll: true,
      ),
    );

    // Group by directory in a single pass
    final albumMap = <String, List<AvesEntry>>{};
    for (final entry in filteredEntries) {
      final pathStr = entry.path;
      if (pathStr != null) {
        // Optimized way to get parent path without creating multiple File objects
        final lastSeparator = pathStr.lastIndexOf('/');
        if (lastSeparator != -1) {
          final parentPath = pathStr.substring(0, lastSeparator);
          albumMap.putIfAbsent(parentPath, () => []).add(entry);
        }
      }
    }

    // Add individual albums. They inherit the sorting order of the parent list.
    albumMap.forEach((path, folderEntries) {
      final name = path.split('/').last;
      albums.add(AlbumModel(id: path, name: name, entries: folderEntries));
    });

    return albums;
  }

  // Fetches a list of asset paths (albums), typically starting with "Recent".
  Future<List<AlbumModel>> getPhotos() async {
    if (_isInitialized && _cachedAlbums != null) return _cachedAlbums!;

    // Initial load from DB if not already done
    if (!_isInitialized) {
      final dbEntries = await _db.getAllEntries();
      if (dbEntries.isNotEmpty) {
        _allEntries = dbEntries;
        _cachedAlbums = _groupEntries(_allEntries);
        _isInitialized = true;

        // Start background sync to find new/missing files
        unawaited(_backgroundSync());

        return _cachedAlbums!;
      } else {
        // TOP ENTRIES for prioritized Re-launch
        // We load what was visible last time for instant recovery
        final topIds = SettingsService().topEntryIds;
        if (topIds.isNotEmpty) {
          final topEntries = await _db.getEntriesByIds(topIds);
          if (topEntries.isNotEmpty) {
            _allEntries = topEntries;
            _cachedAlbums = _groupEntries(_allEntries);
            // We don't set _isInitialized = true yet because this is just above-the-fold
            unawaited(_backgroundSync());
            return _cachedAlbums!;
          }
        }
      }
    }

    // If DB is empty, perform a full fetch
    final albums = await _fetchAllMediaAndGroup();
    _cachedAlbums = albums;
    _isInitialized = true;
    return albums;
  }

  Future<void> _backgroundSync() async {
    // Silently update _allEntries in background
    await for (final _ in getMediaStream()) {
      // getMediaStream already updates DB and _allEntries logic is handled there
    }
  }

  // Provides a stream of media entries to allow for instant UI updates.
  // It emits cached entries immediately and then starts a native sync.
  Future<AvesEntry?> refreshEntry(AvesEntry entry) async {
    final id = entry.contentId;
    if (id == null) return null;
    final updated = await _db.getEntry(id);
    if (updated != null) {
      _entryUpdateController.add(updated);
    }
    return updated;
  }

  void notifyEntryUpdated(AvesEntry entry) {
    _entryUpdateController.add(entry);
  }

  void notifyAlbumUpdated() {
    _albumUpdateController.add(null);
  }

  Future<void> deleteEntry(AvesEntry entry) async {
    final id = entry.contentId;
    if (id == null) return;

    // Synchronous memory update
    _allEntries.removeWhere((e) => e.contentId == id);
    _cachedAlbums = _groupEntries(_allEntries);

    // Background persistence
    await _db.deleteEntries([id]);
    _entryDeletedController.add(id);
    _albumUpdateController.add(null);
  }

  Future<void> scrubMissingEntries() async {
    final entries = await _db.getAllEntries();
    final toDelete = <int>[];

    for (final entry in entries) {
      final path = entry.path;
      if (path != null && !File(path).existsSync()) {
        if (entry.contentId != null) {
          toDelete.add(entry.contentId!);
        }
      }
    }

    if (toDelete.isNotEmpty) {
      debugPrint('Scrubbing ${toDelete.length} orphan entries from DB');
      await _db.deleteEntries(toDelete);
      _cachedAlbums = null;
      _albumUpdateController.add(null);
      for (final id in toDelete) {
        _entryDeletedController.add(id);
      }
    }
  }

  Stream<AvesEntry> getMediaStream() async* {
    // 1. Emit existing entries from DB instantly
    // If we only have partial "Top Entries", we need to load the rest now
    final dbEntries = await _db.getAllEntries();

    // Merge: update _allEntries with the full DB set, keeping memory instances if they exist
    if (_allEntries.length < dbEntries.length) {
      final existingIds = _allEntries
          .where((e) => e.contentId != null)
          .map((e) => e.contentId)
          .toSet();
      for (final dbEntry in dbEntries) {
        if (!existingIds.contains(dbEntry.contentId)) {
          _allEntries.add(dbEntry);
        }
      }
      _allEntries.sort(
        (a, b) =>
            (b.dateModifiedMillis ?? 0).compareTo(a.dateModifiedMillis ?? 0),
      );
      _cachedAlbums = _groupEntries(_allEntries);
      _albumUpdateController.add(null);
    } else if (_allEntries.isEmpty) {
      _allEntries = dbEntries;
    }

    for (final entry in _allEntries) {
      if (_trashService.isTrashed(entry.path)) continue;
      yield entry;
    }

    // 2. Start orphan cleanup in background
    unawaited(scrubMissingEntries());

    // 3. Start native sync
    final known = await _db.getKnownEntries();

    int totalItems = 0;
    int currentItems = 0;

    final progressSub = (_service as PlatformMediaStoreService).syncProgress
        .listen((p) {
          totalItems = p['total'] ?? 0;
        });

    final newEntries = <AvesEntry>[];
    await for (final entry in _service.getEntries(known)) {
      if (_trashService.isTrashed(entry.path)) continue;

      // De-duplicate if we have prioritized entries or skeletons
      final existingIndex = _allEntries.indexWhere(
        (e) => e.contentId != null && e.contentId == entry.contentId,
      );

      if (existingIndex != -1) {
        _allEntries[existingIndex] = entry; // Replace skeleton with real entry
      } else {
        _allEntries.add(entry);
        // Regroup to show new items
        _allEntries.sort(
          (a, b) =>
              (b.dateModifiedMillis ?? 0).compareTo(a.dateModifiedMillis ?? 0),
        );
        _cachedAlbums = _groupEntries(_allEntries);
      }

      newEntries.add(entry);
      currentItems++;

      if (totalItems > 0 && currentItems % 50 == 0) {
        _notifications.showIndexingProgress(currentItems, totalItems);
      }

      // Periodically notify UI
      if (currentItems % 10 == 0) {
        _albumUpdateController.add(null);
      }

      yield entry; // Emit new/updated entries as they arrive
    }

    progressSub.cancel();
    _notifications.dismissIndexingProgress();

    // 4. Save new entries to DB
    if (newEntries.isNotEmpty) {
      await _db.saveEntries(newEntries);
    }

    // 5. Handle removals (obsolete entries)
    final knownIds = known.keys.whereType<int>().toList();
    if (knownIds.isNotEmpty) {
      final obsoleteIds = await _service.checkObsoleteContentIds(knownIds);
      if (obsoleteIds.isNotEmpty) {
        await _db.deleteEntries(obsoleteIds);
        _allEntries.removeWhere(
          (e) => e.contentId != null && obsoleteIds.contains(e.contentId),
        );
        _cachedAlbums = _groupEntries(_allEntries);
        _albumUpdateController.add(null);
      }
    }

    // 6. Start Deep Indexing (Cataloging)
    _catalog.startCataloging();
  }

  // Fetches all albums, optionally excluding or sorting them.
  Future<List<AlbumModel>> getAlbums() async {
    final List<AlbumModel> paths = await getPhotos();

    if (paths.isEmpty) return [];

    final List<AlbumModel> filteredAlbums = paths
        .where((a) => !a.isAll)
        .toList();

    // Sort albums alphabetically by name
    filteredAlbums.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return filteredAlbums;
  }

  // Fetches all media assets from a given album at once.
  Future<List<PhotoModel>> getAllMedia({required AlbumModel album}) async {
    return album.entries
        .map(
          (entry) => PhotoModel(
            uid: entry.id,
            asset: entry,
            timeTaken: entry.bestDate ?? DateTime.now(),
            isVideo: entry.isVideo,
          ),
        )
        .toList();
  }

  // Fetches specific media assets from a given album.
  // Supports pagination.
  Future<List<PhotoModel>> getMedia({
    required AlbumModel album,
    required int page,
    int size = 50,
  }) async {
    final start = page * size;
    if (start >= album.entries.length) return [];

    final end = (start + size) > album.entries.length
        ? album.entries.length
        : (start + size);
    final assets = album.entries.sublist(start, end);

    return assets
        .map(
          (entry) => PhotoModel(
            uid: entry.id,
            asset: entry,
            timeTaken: entry.bestDate ?? DateTime.now(),
            isVideo: entry.isVideo,
          ),
        )
        .toList();
  }

  // Fetches all assets marked as favorites across all albums.
  Future<List<PhotoModel>> getFavorites() async {
    // Always load from database since favorites are in separate table
    final entries = await _db.getFavoriteEntries();
    return entries
        .map(
          (entry) => PhotoModel(
            uid: entry.id,
            asset: entry,
            timeTaken: entry.bestDate ?? DateTime.now(),
            isVideo: entry.isVideo,
          ),
        )
        .toList();
  }

  Future<void> toggleFavorite(AvesEntry entry) async {
    if (entry.contentId == null) return;

    // Use FavouritesManager which handles both DB and in-memory state
    await favouritesManager.toggle(entry);

    // Notify UI of change
    _entryUpdateController.add(entry);
  }

  // Groups a flat list of photos by their date (Month-Day-Year).
  // Returns a flattened list of headers (Strings) and rows (List<PhotoModel>).
  // This is optimized for ListView rendering without nested GridViews.
  static List<dynamic> groupPhotosByDate(
    List<PhotoModel> photos, {
    int columnCount = 4,
  }) {
    if (photos.isEmpty) return [];

    List<dynamic> grouped = [];
    List<PhotoModel> dayPhotos = [];

    DateTime? lastDate;

    void flushDay() {
      if (dayPhotos.isNotEmpty) {
        // Break day photos into rows of columnCount
        for (var i = 0; i < dayPhotos.length; i += columnCount) {
          final row = dayPhotos.sublist(
            i,
            (i + columnCount) > dayPhotos.length
                ? dayPhotos.length
                : (i + columnCount),
          );
          grouped.add(row);
        }
        dayPhotos.clear();
      }
    }

    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final date = photo.timeTaken;
      final isSameDay =
          lastDate != null &&
          date.year == lastDate.year &&
          date.month == lastDate.month &&
          date.day == lastDate.day;

      if (!isSameDay) {
        flushDay();
        grouped.add(DateFormat('MMMM d, yyyy').format(date));
        lastDate = date;
      }

      // We store the global index with the photo to avoid indexOf lookups later
      photo.index = i;
      dayPhotos.add(photo);
    }

    flushDay();
    return grouped;
  }
}
