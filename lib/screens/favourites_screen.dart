import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../services/media_service.dart';
import '../models/photo_model.dart';
import '../screens/viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/trash_service.dart';
import 'package:m3e_collection/m3e_collection.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();
  List<PhotoModel> _photos = [];
  List<dynamic> _groupedItems = [];
  bool _loading = true;

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  Future<void> _init() async {
    setState(() => _loading = true);
    await _trashService.init();
    final media = await _service.getFavorites();
    setState(() {
      _photos = media;
      _groupedItems = MediaService.groupPhotosByDate(media);
      _loading = false;
    });
  }

  void _onGalleryChange(MethodCall call) {
    _init();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelecting = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    for (var id in _selectedIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        await _trashService.moveToTrash(asset);
      }
    }
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    _init();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Moved selected items to trash")),
      );
    }
  }

  Future<void> _shareSelected() async {
    List<XFile> files = [];
    for (var id in _selectedIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        final file = await asset.file;
        if (file != null) files.add(XFile(file.path));
      }
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    }
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
    PhotoManager.addChangeCallback(_onGalleryChange);
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onGalleryChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelecting) {
          setState(() {
            _isSelecting = false;
            _selectedIds.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBarM3E(
          title: _isSelecting
              ? Text(
                  "${_selectedIds.length} Selected",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  "Favourites",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          centerTitle: false,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: _isSelecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelecting = false;
                      _selectedIds.clear();
                    });
                  },
                )
              : null,
          actions: _isSelecting
              ? [
                  IconButton(
                    onPressed: _shareSelected,
                    icon: const Icon(Icons.share),
                  ),
                  IconButton(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete),
                  ),
                ]
              : [],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _photos.isEmpty
            ? const Center(child: Text("No favourites yet"))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_photos.length} favourites',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      cacheExtent: 1500,
                      itemCount: _groupedItems.length,
                      itemBuilder: (context, index) {
                        final item = _groupedItems[index];

                        if (item is String) {
                          return Container(
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
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                            itemCount: item.length,
                            itemBuilder: (context, idx) {
                              final photo = item[idx];
                              final globalIndex = _photos.indexOf(photo);
                              final isSelected = _selectedIds.contains(
                                photo.asset.id,
                              );

                              return GestureDetector(
                                onLongPress: () {
                                  if (!_isSelecting) {
                                    setState(() => _isSelecting = true);
                                    _toggleSelection(photo.asset.id);
                                  }
                                },
                                onTap: () async {
                                  if (_isSelecting) {
                                    _toggleSelection(photo.asset.id);
                                  } else {
                                    final paths =
                                        await PhotoManager.getAssetPathList(
                                          type: RequestType.common,
                                        );
                                    if (!context.mounted) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ViewerScreen(
                                          index: globalIndex,
                                          initialPhotos: _photos,
                                          sourceAlbums: paths.first,
                                        ),
                                      ),
                                    );
                                    _init(); // Refresh to reflect changes
                                  }
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AssetEntityImage(
                                      photo.asset,
                                      isOriginal: false,
                                      thumbnailSize: const ThumbnailSize.square(
                                        200,
                                      ),
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
                ],
              ),
      ),
    );
  }
}
