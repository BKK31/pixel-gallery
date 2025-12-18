import 'package:photo_manager/photo_manager.dart';


class PhotoModel {
  final String uid;
  final AssetEntity asset;
  final DateTime timeTaken;

  PhotoModel({
    required this.uid,
    required this.asset,
    required this.timeTaken,
  });
}