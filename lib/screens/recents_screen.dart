import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina_gallery/models/photo_model.dart';
import 'package:lumina_gallery/screens/viewer_screen.dart';
import 'package:lumina_gallery/services/media_service.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';

class RecentsScreen extends StatefulWidget {
  final Function(bool, int)? onSelectionChanged;

  const RecentsScreen({Key? key, this.onSelectionChanged}) : super(key: key);

  @override
  RecentsScreenState createState() => RecentsScreenState();
}

class RecentsScreenState extends State<RecentsScreen>
    with AutomaticKeepAliveClientMixin {
  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();
  final ScrollController _scrollController = ScrollController();

  List<PhotoModel> _photos = [];
  List<dynamic> _groupedItems = [];
  AssetPathEntity? _currentAlbum;

  bool _loading = true;
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  @override
  bool get wantKeepAlive => true;

  Future<void> _init() async {
    final perm = await _service.requestPermission();
    await _trashService.init();
    await _trashService.requestPermission();

    if (!perm) return;

    final albums = await _service.getPhotos();
    _currentAlbum = albums.first;

    final media = await _service.getAllMedia(album: _currentAlbum!);

    setState(() {
      _photos = media.toList();
      _groupedItems = MediaService.groupPhotosByDate(_photos);
      _loading = false;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelecting = false;
      } else {
        _selectedIds.add(id);
        _isSelecting = true;
      }
    });

    widget.onSelectionChanged?.call(_isSelecting, _selectedIds.length);
  }

  void clearSelections() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    widget.onSelectionChanged?.call(false, 0);
  }

  Future<void> deleteSelected() async {
    for (final id in _selectedIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        await _trashService.moveToTrash(asset);
      }
    }
    clearSelections();
    _init();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Moved selected items to trash")),
      );
    }
  }

  Future<void> shareSelected() async {
    final List<XFile> files = [];

    for (final id in _selectedIds) {
      final asset = await AssetEntity.fromId(id);
      final file = await asset?.file;
      if (file != null) {
        files.add(XFile(file.path));
      }
    }

    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    }

    clearSelections();
  }

  @override
  void initState() {
    super.initState();
    _init();

    PhotoManager.addChangeCallback((MethodCall call) => _init());
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback((_) {});
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_currentAlbum != null)
          FutureBuilder<int>(
            future: _currentAlbum!.assetCountAsync,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${snapshot.data} photos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ListView.builder(
              cacheExtent: 1500,
              controller: _scrollController,
              itemCount: _groupedItems.length,
              itemBuilder: (context, index) {
                final item = _groupedItems[index];

                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                } else if (item is List<PhotoModel>) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                        ),
                    itemCount: item.length,
                    itemBuilder: (context, idx) {
                      final photo = item[idx];
                      final globalIndex = _photos.indexOf(photo);
                      final isSelected = _selectedIds.contains(photo.asset.id);

                      return GestureDetector(
                        onLongPress: () => _toggleSelection(photo.asset.id),
                        onTap: () async {
                          if (_isSelecting) {
                            _toggleSelection(photo.asset.id);
                          } else {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewerScreen(
                                  index: globalIndex,
                                  initialPhotos: List.unmodifiable(_photos),
                                  sourceAlbums: _currentAlbum!,
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AssetEntityImage(
                              photo.asset,
                              thumbnailSize: const ThumbnailSize.square(180),
                              thumbnailFormat: ThumbnailFormat.jpeg,
                              fit: BoxFit.cover,
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                ),
                              ),
                            if (photo.isVideo && !isSelected)
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill_outlined,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }
}
