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
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      return false;
    }
    return true;
  }

  Future<List<AssetPathEntity>> getPhotos() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: _filterOption,
    );
    return paths;
  }

  Future<List<AssetPathEntity>> getAlbums() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.all,
      filterOption: _filterOption,
    );

    if (paths.isEmpty) return [];

    final otherAlbums = paths.sublist(1);

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
