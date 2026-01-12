import 'package:lumina_gallery/models/aves_entry.dart';

class AlbumModel {
  final String id;
  final String name;
  final List<AvesEntry> entries;
  final bool isAll;

  AlbumModel({
    required this.id,
    required this.name,
    required this.entries,
    this.isAll = false,
  });

  int get assetCount => entries.length;

  // For compatibility with photo_manager checks if ever used
  bool get isRecent => name == 'Recent' || name == 'All';
}
