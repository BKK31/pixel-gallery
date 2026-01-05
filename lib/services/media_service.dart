import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';

// Service responsible for fetching and managing media assets (photos/videos)
// and albums using PhotoManager.
class MediaService {
  // Options for filtering and sorting assets (Date Descending).
  final FilterOptionGroup _filterOption = FilterOptionGroup(
    orders: [
      OrderOption(type: OrderOptionType.createDate, asc: false),
      OrderOption(type: OrderOptionType.updateDate, asc: false),
    ],
  );

  // Requests permissions to access the device's photo library.
  // Returns true if access is granted.
  Future<bool> requestPermission() async {
    // Request permission to access photos and videos
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      return false;
    }
    return true;
  }

  // Fetches a list of asset paths (albums), typically starting with "Recent".
  Future<List<AssetPathEntity>> getPhotos() async {
    // Fetch recent assets (photos and videos) with the defined filter options
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: _filterOption,
    );
    return paths;
  }

  // Fetches all albums, optionally excluding or sorting them.
  // Currently sorts alphabetically and excludes the first album (typically "Recents")
  // from the returned list.
  Future<List<AssetPathEntity>> getAlbums() async {
    // Fetch all albums, utilizing RequestType.common to include ONLY images and videos (no audio)
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: _filterOption,
    );

    if (paths.isEmpty) return [];

    final List<AssetPathEntity> filteredAlbums = [];

    for (final path in paths) {
      // Use assetCountAsync as assetCount is deprecated/removed in newer versions
      final int count = await path.assetCountAsync;
      if (count > 0 && !path.isAll) {
        filteredAlbums.add(path);
      }
    }

    // Sort albums alphabetically by name
    filteredAlbums.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return filteredAlbums;
  }

  // Fetches specific media assets from a given album.
  // Supports pagination.
  // Returns a list of PhotoModel objects.
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

  // Fetches all assets marked as favorites across all albums.
  Future<List<PhotoModel>> getFavorites() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
        containsPathModified: true,
      ),
    );

    if (paths.isEmpty) return [];

    // The first path is usually "Recent" (all assets)
    final AssetPathEntity allPath = paths.first;

    // We fetch a large number or all, but for now let's fetch a reasonable amount
    // or use a more specific filter if possible.
    final List<AssetEntity> assets = await allPath.getAssetListRange(
      start: 0,
      end: 10000,
    );
    return assets
        .where((asset) => asset.isFavorite)
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
