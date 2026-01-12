import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/services/channel.dart';

final MediaFetchService mediaFetchService = MediaFetchService();

class MediaFetchService {
  final _mediaByteStreamChannel = AvesStreamsChannel(
    'com.pixel.gallery/media_byte_stream',
  );

  // In-memory cache for decoders to provide instant access during scrolling
  static final Map<String, ui.Codec> _memoryCache = {};
  static const int _maxInMemoryThumbnails = 400;

  Directory? _persistentThumbDir;

  Future<File> _getCacheFile(AvesEntry entry, double extent) async {
    if (_persistentThumbDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _persistentThumbDir = Directory(p.join(appDir.path, 'thumbnails'));
      if (!_persistentThumbDir!.existsSync()) {
        _persistentThumbDir!.createSync(recursive: true);
      }
    }

    // Stable key using path (preferred) or URI + last modified
    final stableId = entry.path ?? entry.uri;
    final safeId = stableId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileName =
        '${safeId}_${entry.dateModifiedMillis}_${extent.toInt()}.jpg';
    return File(p.join(_persistentThumbDir!.path, fileName));
  }

  Future<ui.Codec> getThumbnail({
    required AvesEntry entry,
    required double extent,
    double? devicePixelRatio,
  }) async {
    final stableId = entry.path ?? entry.uri;
    final cacheKey =
        '${stableId}_${entry.dateModifiedMillis}_${extent.toInt()}';

    // 1. Check Memory Cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    final cacheFile = await _getCacheFile(entry, extent);

    // 2. Check Disk Cache
    if (await cacheFile.exists()) {
      try {
        final bytes = await cacheFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        _updateMemoryCache(cacheKey, codec);
        return codec;
      } catch (e) {
        debugPrint('MediaFetchService failed to read cache: $e');
      }
    }

    // 3. Native Fetch
    final Completer<ui.Codec> completer = Completer();
    final bytes = <int>[];

    _mediaByteStreamChannel
        .receiveBroadcastStream({
          'op': 'getThumbnail',
          'uri': entry.uri,
          'mimeType': entry.sourceMimeType,
          'dateModifiedMillis': entry.dateModifiedMillis,
          'rotationDegrees': entry.sourceRotationDegrees,
          'isFlipped': false,
          'widthDip': extent,
          'heightDip': extent,
          'defaultSizeDip': 256.0,
          'quality': 90,
          'decoded': false,
        })
        .listen(
          (data) {
            if (data is List<int>) {
              bytes.addAll(data);
            } else if (data is int) {
              if (data == 202) {
                final uint8Bytes = Uint8List.fromList(bytes);
                // Save to cache asynchronously
                _saveToDisk(cacheFile, uint8Bytes);

                ui.instantiateImageCodec(uint8Bytes).then((codec) {
                  _updateMemoryCache(cacheKey, codec);
                  completer.complete(codec);
                });
              }
            }
          },
          onError: (error) {
            debugPrint('MediaFetchService getThumbnail error: $error');
            completer.completeError(error);
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError('Stream closed before image was loaded');
            }
          },
          cancelOnError: true,
        );

    return completer.future;
  }

  void _updateMemoryCache(String key, ui.Codec codec) {
    if (_memoryCache.length >= _maxInMemoryThumbnails) {
      _memoryCache.remove(_memoryCache.keys.first); // Basic eviction
    }
    _memoryCache[key] = codec;
  }

  Future<void> _saveToDisk(File file, Uint8List bytes) async {
    try {
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('MediaFetchService failed to write cache: $e');
    }
  }
}
