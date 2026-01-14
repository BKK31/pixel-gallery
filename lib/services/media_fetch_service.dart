import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/services/channel.dart';

final MediaFetchService mediaFetchService = MediaFetchService();

class MediaFetchService with WidgetsBindingObserver {
  final _mediaByteStreamChannel = AvesStreamsChannel(
    'com.pixel.gallery/media_byte_stream',
  );

  // Track pending requests to avoid duplicate fetches
  static final Map<String, List<Completer<ui.Codec>>> _pendingRequests = {};

  MediaFetchService() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _clearPendingRequests();
    }
  }

  void _clearPendingRequests() {
    for (final pending in _pendingRequests.values) {
      for (final completer in pending) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('App lifecycle: request cancelled'),
          );
        }
      }
    }
    _pendingRequests.clear();
  }

  Future<ui.Codec> getThumbnail({
    required AvesEntry entry,
    required double extent,
    double? devicePixelRatio,
  }) async {
    final stableId = entry.path ?? entry.uri;
    final cacheKey =
        '${stableId}_${entry.dateModifiedMillis}_${extent.toInt()}';

    // Check pending requests
    if (_pendingRequests.containsKey(cacheKey)) {
      final completer = Completer<ui.Codec>();
      _pendingRequests[cacheKey]!.add(completer);
      return completer.future;
    }

    _pendingRequests[cacheKey] = [];

    final Completer<ui.Codec> completer = Completer();
    final sink = BytesBuilder(copy: false);

    _mediaByteStreamChannel
        .receiveBroadcastStream({
          'op': 'getThumbnail',
          'uri': entry.uri,
          'mimeType': entry.sourceMimeType,
          'dateModifiedMillis': entry.dateModifiedMillis,
          'rotationDegrees': entry.sourceRotationDegrees,
          'isFlipped': false,
          'pageId': null,
          'widthDip': extent,
          'heightDip': extent,
          'defaultSizeDip': 64.0,
          'quality': 100,
          'decoded': false,
        })
        .listen(
          (data) {
            if (data is List<int>) {
              sink.add(data);
            } else if (data is int) {
              // Aves sometimes sends single bytes/status, but typically writes lists.
              // If we receive a single int, handle it if needed.
              // In Aves implementation, it streams Uint8List chunks.
            }
          },
          onError: (error) {
            debugPrint('MediaFetchService getThumbnail stream error: $error');
            if (!completer.isCompleted) completer.completeError(error);
            _rejectPendingRequests(cacheKey, error);
          },
          onDone: () async {
            if (sink.isEmpty) {
              final error = Exception(
                'Stream closed with no data for ${entry.uri}',
              );
              if (!completer.isCompleted) completer.completeError(error);
              _rejectPendingRequests(cacheKey, error);
              return;
            }

            try {
              final bytes = sink.takeBytes();
              // Check trailer
              if (bytes.isNotEmpty) {
                final trailer = bytes.last;
                // 0xCA = 202 (Encoded)
                if (trailer == 202) {
                  final imageData = Uint8List.sublistView(
                    bytes,
                    0,
                    bytes.length - 1,
                  );
                  final codec = await ui.instantiateImageCodec(imageData);
                  if (!completer.isCompleted) completer.complete(codec);
                  _resolvePendingRequests(cacheKey, codec);
                  return;
                } else if (trailer == 254) {
                  // 0xFE (Decoded / Raw) - Not fully implemented yet
                  // Handle raw bytes if needed, but for now assuming encoded
                }
              }

              // Fallback if no trailer or unknown
              final codec = await ui.instantiateImageCodec(bytes);
              if (!completer.isCompleted) completer.complete(codec);
              _resolvePendingRequests(cacheKey, codec);
            } catch (e) {
              debugPrint('MediaFetchService codec error: $e');
              if (!completer.isCompleted) completer.completeError(e);
              _rejectPendingRequests(cacheKey, e);
            }
          },
          cancelOnError: true,
        );

    return completer.future;
  }

  void _resolvePendingRequests(String key, ui.Codec codec) {
    final pending = _pendingRequests.remove(key);
    if (pending != null) {
      for (final completer in pending) {
        if (!completer.isCompleted) {
          completer.complete(codec);
        }
      }
    }
  }

  void _rejectPendingRequests(String key, Object error) {
    final pending = _pendingRequests.remove(key);
    if (pending != null) {
      for (final completer in pending) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }
    }
  }
}
