import 'package:lumina_gallery/models/aves_entry.dart';

// Data model representing a single photo or video asset.
class PhotoModel {
  final String uid;
  AvesEntry asset;
  final DateTime timeTaken;
  final bool isVideo;
  int? index;

  PhotoModel({
    required this.uid,
    required this.asset,
    required this.timeTaken,
    required this.isVideo,
    this.index,
  });
}
