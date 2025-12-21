import 'package:photo_manager/photo_manager.dart';

class PhotoModel {
  final String uid;
  AssetEntity asset;
  final DateTime timeTaken;
  final bool isVideo;

  PhotoModel({
    required this.uid,
    required this.asset,
    required this.timeTaken,
    required this.isVideo,
  });
}
