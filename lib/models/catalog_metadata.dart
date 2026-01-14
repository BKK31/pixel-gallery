/// Model for catalogued metadata (EXIF, XMP data extracted during cataloging).
/// This is stored separately from the core entry data for better organization.
class CatalogMetadata {
  final int id; // References AvesEntry.contentId
  final double? latitude;
  final double? longitude;
  final String? xmpSubjects; // Comma-separated tags/keywords
  final String? xmpTitle; // Custom title from XMP
  final int? rating; // Star rating (0-5)

  CatalogMetadata({
    required this.id,
    this.latitude,
    this.longitude,
    this.xmpSubjects,
    this.xmpTitle,
    this.rating,
  });

  factory CatalogMetadata.fromMap(Map<String, dynamic> map) {
    return CatalogMetadata(
      id: map['id'] as int,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      xmpSubjects: map['xmpSubjects'] as String?,
      xmpTitle: map['xmpTitle'] as String?,
      rating: map['rating'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'xmpSubjects': xmpSubjects,
      'xmpTitle': xmpTitle,
      'rating': rating,
    };
  }

  bool get hasLocation => latitude != null && longitude != null;

  CatalogMetadata copyWith({
    double? latitude,
    double? longitude,
    String? xmpSubjects,
    String? xmpTitle,
    int? rating,
  }) {
    return CatalogMetadata(
      id: id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      xmpSubjects: xmpSubjects ?? this.xmpSubjects,
      xmpTitle: xmpTitle ?? this.xmpTitle,
      rating: rating ?? this.rating,
    );
  }
}
