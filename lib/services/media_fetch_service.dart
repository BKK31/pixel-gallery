import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/services/channel.dart';
import 'package:lumina_gallery/services/service_policy.dart';

final MediaFetchService mediaFetchService = MediaFetchService();

class MediaFetchService with WidgetsBindingObserver {
  final _mediaByteStreamChannel = AvesStreamsChannel(
    'com.pixel.gallery/media_byte_stream',
  );

  MediaFetchService() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Potentially clear or pause all requests here if needed,
      // but ServicePolicy manages its own state.
    }
  }

  Future<ui.Codec> getThumbnail({
    required AvesEntry entry,
    required double extent,
    double? devicePixelRatio,
    int? priority,
    Object? taskKey,
  }) async {
    final stableId = entry.path ?? entry.uri;
    taskKey ??= '${stableId}_${entry.dateModifiedMillis}_${extent.toInt()}';

    return servicePolicy.call(
      () async {
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
                }
              },
              onError: (error) {
                debugPrint(
                  'MediaFetchService getThumbnail stream error: $error',
                );
                if (!completer.isCompleted) completer.completeError(error);
              },
              onDone: () async {
                if (sink.isEmpty) {
                  final error = Exception(
                    'Stream closed with no data for ${entry.uri}',
                  );
                  if (!completer.isCompleted) completer.completeError(error);
                  return;
                }

                try {
                  final bytes = sink.takeBytes();
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
                      return;
                    }
                  }

                  final codec = await ui.instantiateImageCodec(bytes);
                  if (!completer.isCompleted) completer.complete(codec);
                } catch (e) {
                  debugPrint('MediaFetchService codec error: $e');
                  if (!completer.isCompleted) completer.completeError(e);
                }
              },
              cancelOnError: true,
            );

        return completer.future;
      },
      priority:
          priority ??
          (extent <= 100
              ? ServiceCallPriority.getFastThumbnail
              : ServiceCallPriority.getSizedThumbnail),
      key: taskKey,
    );
  }

  bool cancelThumbnail(Object taskKey) => servicePolicy.cancel(taskKey, [
    ServiceCallPriority.getFastThumbnail,
    ServiceCallPriority.getSizedThumbnail,
  ]);

  bool pauseThumbnail(Object taskKey) => servicePolicy.pause(taskKey, [
    ServiceCallPriority.getFastThumbnail,
    ServiceCallPriority.getSizedThumbnail,
  ]);

  Future<T>? resumeThumbnail<T>(Object taskKey) =>
      servicePolicy.resume<T>(taskKey);
}
