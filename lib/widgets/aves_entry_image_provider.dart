import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/services/media_fetch_service.dart';

class AvesEntryImageProvider extends ImageProvider<AvesEntryImageProviderKey> {
  final AvesEntry entry;
  final double? extent;

  const AvesEntryImageProvider(this.entry, {this.extent});

  @override
  Future<AvesEntryImageProviderKey> obtainKey(
    ImageConfiguration configuration,
  ) {
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
    if (key.extent != null) {
      try {
        return await mediaFetchService.getThumbnail(
          entry: entry,
          extent: key.extent!,
        );
      } catch (e) {
        debugPrint('AvesEntryImageProvider _loadAsync thumbnail failed: $e');
      }
    }

    // Fallback to full image loading if extent is null or thumbnail fails
    final file = await entry.file;
    if (file == null) {
      throw Exception('Failed to get file for AvesEntry: ${entry.uri}');
    }

    final Uint8List bytes = await file.readAsBytes();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes,
    );
    return decode(buffer);
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
