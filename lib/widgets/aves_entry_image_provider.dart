import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/services/media_fetch_service.dart';
import 'package:lumina_gallery/services/entry_cache.dart';

class AvesEntryImageProvider extends ImageProvider<AvesEntryImageProviderKey> {
  final AvesEntry entry;
  final double? extent;

  const AvesEntryImageProvider(this.entry, {this.extent});

  @override
  Future<AvesEntryImageProviderKey> obtainKey(
    ImageConfiguration configuration,
  ) {
    // Mark this extent as used for future cache eviction
    if (extent != null) {
      EntryCache.markThumbnailExtent(extent!);
    }

    return SynchronousFuture<AvesEntryImageProviderKey>(
      AvesEntryImageProviderKey(
        uri: entry.uri,
        dateModifiedMillis: entry.dateModifiedMillis ?? 0,
        extent: extent?.roundToDouble(),
      ),
    );
  }

  @override
  ImageStreamCompleter loadImage(
    AvesEntryImageProviderKey key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('uri: ${entry.uri}'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AvesEntryImageProviderKey key,
    ImageDecoderCallback decode,
  ) async {
    try {
      if (key.extent != null) {
        return await mediaFetchService.getThumbnail(
          entry: entry,
          extent: key.extent!,
        );
      }

      // For full image requests (extent = null), load from file or define getFullImage in service
      // Currently assuming usage is mostly for thumbnails.
      // Falling back to file read for full image if intent is full load.
      final file = await entry.file;
      if (file == null) {
        throw Exception('Failed to get file for AvesEntry: ${entry.uri}');
      }
      final Uint8List bytes = await file.readAsBytes();
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        bytes,
      );
      return decode(buffer);
    } catch (e) {
      debugPrint(
        'AvesEntryImageProvider failed for uri=${entry.uri} extent=${key.extent}: $e',
      );
      throw e;
    }
  }

  /// Evicts image from Flutter's image cache.
  /// Used by EntryCache when an entry's visual properties change.
  static Future<void> evictFromCache({
    required String uri,
    required int dateModifiedMillis,
    double? extent,
  }) async {
    final key = AvesEntryImageProviderKey(
      uri: uri,
      dateModifiedMillis: dateModifiedMillis,
      extent: extent?.roundToDouble(),
    );

    await PaintingBinding.instance.imageCache.evict(key);
  }
}

@immutable
class AvesEntryImageProviderKey {
  final String uri;
  final int dateModifiedMillis;
  final double? extent;

  const AvesEntryImageProviderKey({
    required this.uri,
    required this.dateModifiedMillis,
    this.extent,
  });

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AvesEntryImageProviderKey &&
        other.uri == uri &&
        other.dateModifiedMillis == dateModifiedMillis &&
        other.extent == extent;
  }

  @override
  int get hashCode => Object.hash(uri, dateModifiedMillis, extent);
}
