import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/services/channel.dart';
import 'package:flutter/services.dart';

abstract class MediaStoreService {
  Future<List<int>> checkObsoleteContentIds(List<int?> knownContentIds);

  Future<List<int>> checkObsoletePaths(Map<int?, String?> knownPathById);

  Future<List<String>> getChangedUris(int sinceGeneration);

  // knownEntries: map of contentId -> dateModifiedMillis
  Stream<AvesEntry> getEntries(
    Map<int?, int?> knownEntries, {
    String? directory,
  });
}

class PlatformMediaStoreService implements MediaStoreService {
  static const _platform = AvesMethodChannel('com.pixel.gallery/mediastore');
  static final _stream = AvesStreamsChannel(
    'com.pixel.gallery/mediastore_stream',
  );

  @override
  Future<List<int>> checkObsoleteContentIds(List<int?> knownContentIds) async {
    try {
      final result = await _platform.invokeMethod(
        'checkObsoleteContentIds',
        <String, dynamic>{'knownContentIds': knownContentIds},
      );
      return (result as List).cast<int>();
    } on PlatformException catch (e) {
      debugPrint('checkObsoleteContentIds failed: $e');
    }
    return [];
  }

  @override
  Future<List<int>> checkObsoletePaths(Map<int?, String?> knownPathById) async {
    try {
      final result = await _platform.invokeMethod(
        'checkObsoletePaths',
        <String, dynamic>{'knownPathById': knownPathById},
      );
      return (result as List).cast<int>();
    } on PlatformException catch (e) {
      debugPrint('checkObsoletePaths failed: $e');
    }
    return [];
  }

  @override
  Future<List<String>> getChangedUris(int sinceGeneration) async {
    try {
      final result = await _platform.invokeMethod(
        'getChangedUris',
        <String, dynamic>{'sinceGeneration': sinceGeneration},
      );
      return (result as List).cast<String>();
    } on PlatformException catch (e) {
      debugPrint('getChangedUris failed: $e');
    }
    return [];
  }

  final _syncProgressController =
      StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get syncProgress => _syncProgressController.stream;

  @override
  Stream<AvesEntry> getEntries(
    Map<int?, int?> knownEntries, {
    String? directory,
  }) {
    try {
      return _stream
          .receiveBroadcastStream(<String, dynamic>{
            'knownEntries': knownEntries,
            'directory': directory,
          })
          .asyncExpand((event) {
            if (event is Map && event.containsKey('count')) {
              _syncProgressController.add({'total': event['count'] as int});
              return const Stream.empty();
            }
            if (event is List) {
              return Stream.fromIterable(event.cast<Map>());
            } else if (event is Map) {
              return Stream.value(event);
            }
            return const Stream.empty();
          })
          .map((event) {
            final fields = event as Map;
            AvesEntry.normalizeMimeTypeFields(fields);
            return AvesEntry.fromMap(fields);
          });
    } on PlatformException catch (e) {
      debugPrint('getEntries failed: $e');
      return Stream.error(e);
    }
  }
}
