import 'dart:async';
import 'package:flutter/foundation.dart';
import '../widgets/aves_entry_image_provider.dart';

/// Cache management for entry thumbnails and full images.
/// Tracks requested thumbnail extents and provides eviction functionality.
/// Based on Aves's EntryCache implementation.
class EntryCache {
  /// Ordered list of requested thumbnail extents (descending order).
  /// Used to evict all cached thumbnails when an entry changes.
  static final List<double> thumbnailRequestExtents = [];

  /// Marks a thumbnail extent as requested, tracking it for future eviction.
  static void markThumbnailExtent(double extent) {
    if (!thumbnailRequestExtents.contains(extent)) {
      thumbnailRequestExtents
        ..add(extent)
        ..sort((a, b) => b.compareTo(a)); // Descending order
    }
  }

  /// Evicts all cached images (thumbnails and full images) for a given entry.
  /// Should be called when an entry's visual properties change (rotation, edit, etc).
  static Future<void> evict({
    required String uri,
    required int dateModifiedMillis,
    double? extent,
  }) async {
    debugPrint(
      'EntryCache: Evicting cache for uri=$uri, dateModified=$dateModifiedMillis',
    );

    // Evict full image (extent = null)
    await AvesEntryImageProvider.evictFromCache(
      uri: uri,
      dateModifiedMillis: dateModifiedMillis,
      extent: null,
    );

    // Evict all tracked thumbnail sizes
    await Future.forEach<double>(
      thumbnailRequestExtents,
      (extent) => AvesEntryImageProvider.evictFromCache(
        uri: uri,
        dateModifiedMillis: dateModifiedMillis,
        extent: extent,
      ),
    );

    // If specific extent provided, evict that too (in case it's not tracked)
    if (extent != null) {
      await AvesEntryImageProvider.evictFromCache(
        uri: uri,
        dateModifiedMillis: dateModifiedMillis,
        extent: extent,
      );
    }
  }

  /// Evicts cache for multiple URIs (batch operation).
  static Future<void> evictMultiple(List<Map<String, dynamic>> entries) async {
    await Future.forEach<Map<String, dynamic>>(
      entries,
      (entry) => evict(
        uri: entry['uri'] as String,
        dateModifiedMillis: entry['dateModifiedMillis'] as int? ?? 0,
      ),
    );
  }
}
