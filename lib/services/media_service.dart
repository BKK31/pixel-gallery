import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';
import 'package:intl/intl.dart';

// Service responsible for fetching and managing media assets (photos/videos)
// and albums using PhotoManager.
class MediaService {
  // Singleton instance
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // Cache for albums to provide instant access
  List<AssetPathEntity>? _cachedAlbums;

  // Options for filtering and sorting assets (Date Descending).
  final FilterOptionGroup _filterOption = FilterOptionGroup(
    orders: [
      OrderOption(type: OrderOptionType.createDate, asc: false),
      OrderOption(type: OrderOptionType.updateDate, asc: false),
    ],
  );

  // Clears the internal cache, useful when gallery changes are detected.
  void clearCache() {
    _cachedAlbums = null;
  }

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
    if (_cachedAlbums != null) return _cachedAlbums!;
    // Fetch recent assets (photos and videos) with the defined filter options
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: _filterOption,
    );
    _cachedAlbums = paths;
    return paths;
  }

  // Fetches all albums, optionally excluding or sorting them.
  // Currently sorts alphabetically and excludes the first album (typically "Recents")
  // from the returned list.
  Future<List<AssetPathEntity>> getAlbums() async {
    final List<AssetPathEntity> paths = await getPhotos();

    if (paths.isEmpty) return [];

    final List<AssetPathEntity> filteredAlbums = [];

    for (final path in paths) {
      // Use assetCountAsync as assetCount is deprecated/removed in newer versions
      // We don't cache counts as they change, but we load them once per fetch
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

  // Fetches all media assets from a given album at once.
  // This enables continuous scrolling without pagination breaks.
  Future<List<PhotoModel>> getAllMedia({required AssetPathEntity album}) async {
    final int count = await album.assetCountAsync;
    final List<AssetEntity> assets = await album.getAssetListRange(
      start: 0,
      end: count,
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

  // Fetches specific media assets from a given album.
  // Supports pagination.
  // Returns a list of PhotoModel objects.
  Future<List<PhotoModel>> getMedia({
    required AssetPathEntity album,
    required int page,
    int size = 50,
  }) async {
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

  // Groups a flat list of photos by their date (Month-Day-Year).
  // Returns a mixed list of Strings (headers) and List<PhotoModel> (grid rows).
  static List<dynamic> groupPhotosByDate(List<PhotoModel> photos) {
    String? lastDateLabel;
    List<dynamic> grouped = [];
    List<PhotoModel> currentDayPhotos = [];
    for (var photo in photos) {
      var dateLabel = DateFormat('MMMM d, yyyy').format(photo.timeTaken);
      if (dateLabel != lastDateLabel) {
        if (currentDayPhotos.isNotEmpty) {
          grouped.add(List<PhotoModel>.from(currentDayPhotos));
          currentDayPhotos.clear();
        }
        grouped.add(dateLabel);
        lastDateLabel = dateLabel;
      }
      currentDayPhotos.add(photo);
    }
    if (currentDayPhotos.isNotEmpty) {
      grouped.add(currentDayPhotos);
    }
    return grouped;
  }
}
