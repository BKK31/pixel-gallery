import 'dart:io';

class AvesEntry {
  final String uri;
  final String? path;
  final String sourceMimeType;
  final int? width;
  final int? height;
  final int sourceRotationDegrees;
  final int? sizeBytes;
  final int? dateAddedSecs;
  final int? dateModifiedMillis;
  final int? sourceDateTakenMillis;
  final int? durationMillis;
  final int? contentId;

  AvesEntry({
    required this.uri,
    this.path,
    required this.sourceMimeType,
    this.width,
    this.height,
    this.sourceRotationDegrees = 0,
    this.sizeBytes,
    this.dateAddedSecs,
    this.dateModifiedMillis,
    this.sourceDateTakenMillis,
    this.durationMillis,
    this.contentId,
  });

  factory AvesEntry.fromMap(Map map) {
    return AvesEntry(
      uri: map['uri'] as String,
      path: map['path'] as String?,
      sourceMimeType: map['sourceMimeType'] as String,
      width: map['width'] as int?,
      height: map['height'] as int?,
      sourceRotationDegrees: map['sourceRotationDegrees'] as int? ?? 0,
      sizeBytes: map['sizeBytes'] as int?,
      dateAddedSecs: map['dateAddedSecs'] as int?,
      dateModifiedMillis: map['dateModifiedMillis'] as int?,
      sourceDateTakenMillis: map['sourceDateTakenMillis'] as int?,
      durationMillis: map['durationMillis'] as int?,
      contentId: map['contentId'] as int?,
      // Note: latitude, longitude, isCatalogued, isFavorite are ignored
      // They're now in separate tables (metadata, favourites)
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uri': uri,
      'path': path,
      'sourceMimeType': sourceMimeType,
      'width': width,
      'height': height,
      'sourceRotationDegrees': sourceRotationDegrees,
      'sizeBytes': sizeBytes,
      'dateAddedSecs': dateAddedSecs,
      'dateModifiedMillis': dateModifiedMillis,
      'sourceDateTakenMillis': sourceDateTakenMillis,
      'durationMillis': durationMillis,
      'contentId': contentId,
    };
  }

  /// Creates a copy with modified fields
  AvesEntry copyWith({
    String? uri,
    String? path,
    String? sourceMimeType,
    int? width,
    int? height,
    int? sourceRotationDegrees,
    int? sizeBytes,
    int? dateAddedSecs,
    int? dateModifiedMillis,
    int? sourceDateTakenMillis,
    int? durationMillis,
    int? contentId,
  }) {
    return AvesEntry(
      uri: uri ?? this.uri,
      path: path ?? this.path,
      sourceMimeType: sourceMimeType ?? this.sourceMimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      sourceRotationDegrees:
          sourceRotationDegrees ?? this.sourceRotationDegrees,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      dateAddedSecs: dateAddedSecs ?? this.dateAddedSecs,
      dateModifiedMillis: dateModifiedMillis ?? this.dateModifiedMillis,
      sourceDateTakenMillis:
          sourceDateTakenMillis ?? this.sourceDateTakenMillis,
      durationMillis: durationMillis ?? this.durationMillis,
      contentId: contentId ?? this.contentId,
    );
  }

  // AssetEntity compatibility
  String get id => contentId?.toString() ?? uri;

  String? get title => path != null ? path!.split('/').last : null;

  bool get isVideo {
    if (sourceMimeType.startsWith('video/')) return true;
    final lowerPath = path?.toLowerCase();
    if (lowerPath != null) {
      return lowerPath.endsWith('.mp4') ||
          lowerPath.endsWith('.mkv') ||
          lowerPath.endsWith('.mov') ||
          lowerPath.endsWith('.avi') ||
          lowerPath.endsWith('.webm') ||
          lowerPath.endsWith('.3gp');
    }
    return false;
  }

  int get typeInt => isVideo ? 2 : 1; // 1 for image, 2 for video in AssetsType?

  Future<File?> get file async => path != null ? File(path!) : null;

  DateTime? get bestDate {
    final millis = (sourceDateTakenMillis != null && sourceDateTakenMillis! > 0)
        ? sourceDateTakenMillis
        : (dateModifiedMillis != null && dateModifiedMillis! > 0)
        ? dateModifiedMillis
        : (dateAddedSecs != null && dateAddedSecs! > 0)
        ? dateAddedSecs! * 1000
        : null;

    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  static void normalizeMimeTypeFields(Map fields) {
    // Aves uses this to handle some weird MIME types
  }
}
