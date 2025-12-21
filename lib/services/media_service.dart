import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';

class MediaService {
  final FilterOptionGroup _filterOption = FilterOptionGroup(
    orders: [
      OrderOption(type: OrderOptionType.createDate, asc: false),
      OrderOption(type: OrderOptionType.updateDate, asc: false),
    ],
  );

  Future<bool> requestPermission() async {
    // Request permission to access photos and videos
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      return false;
    }
    return true;
  }

  Future<List<AssetPathEntity>> getPhotos() async {
    // Fetch recent assets (photos and videos) with the defined filter options
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: _filterOption,
    );
    return paths;
  }

  Future<List<AssetPathEntity>> getAlbums() async {
    // Fetch all albums, excluding the "Recent" album (usually the first one)
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.all,
      filterOption: _filterOption,
    );

    if (paths.isEmpty) return [];

    // Remove the first album (Recents) to avoid duplication if needed, or strict filtering
    final otherAlbums = paths.sublist(1);

    // Sort albums alphabetically by name
    otherAlbums.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return otherAlbums;
  }

  Future<List<PhotoModel>> getMedia({
    required AssetPathEntity album,
    required int page,
    int size = 50,
  }) async {
    // Fetch a page of assets from a specific album and map them to PhotoModel
    final List<AssetEntity> assets = await album.getAssetListPaged(
      page: page,
      size: size,
    );
    return assets
        .map(
          (asset) => PhotoModel(
            uid: asset.id,
            asset: asset,
            timeTaken: asset.createDateTime,
            isVideo: asset.type == AssetType.video,
          ),
        )
        .toList();
  }
}
