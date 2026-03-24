import 'dart:convert';
import '../models/aves_entry.dart';

/// Base class for all gallery visibility filters
abstract class GalleryFilter {
  const GalleryFilter();

  bool test(AvesEntry entry);

  Map<String, dynamic> toMap();

  factory GalleryFilter.fromMap(Map<String, dynamic> map) {
    final type = map['type'];
    if (type == 'path') {
      return PathFilter(map['path'] as String);
    }
    throw Exception('Unknown GalleryFilter type: $type');
  }

  String toJson() => json.encode(toMap());

  factory GalleryFilter.fromJson(String source) => GalleryFilter.fromMap(json.decode(source));
}

/// A filter that excludes any entry whose path starts with the given string.
class PathFilter extends GalleryFilter {
  final String path;

  PathFilter(this.path);

  @override
  bool test(AvesEntry entry) {
    if (entry.path == null) return false;
    return entry.path!.startsWith(path);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'path',
      'path': path,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PathFilter && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
