import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';

class MediaService {
  AssetPathEntity? _path;
  int _page = 0;
  final int _pageSize = 100;

  Future<void> init() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!ps.hasAccess) {
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.all,
    );

    _path = paths.first;
  }

  Future<List<PhotoModel>> loadNextPage() async {
    if (_path == null) return [];
    final assets = await _path!.getAssetListPaged(page: _page, size: _pageSize);

    _page++;

    return assets.map(
      (asset) => PhotoModel(uid: asset.id, asset: asset, timeTaken: asset.createDateTime)
    ).toList();
  }
}
