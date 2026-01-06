import 'package:flutter/material.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../services/media_service.dart';
import '../models/photo_model.dart';
import '../screens/viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class PhotoScreen extends StatefulWidget {
  final AssetPathEntity album;

  const PhotoScreen({super.key, required this.album});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  List<dynamic> _groupedItems = [];

  final MediaService _service = MediaService();
  List<PhotoModel> _photos = [];
  bool _loading = true;

  ScrollController _scrollController = ScrollController();

  final TrashService _trashService = TrashService();

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  // Initializes the screen by requesting permissions and loading initial assets.
  Future<void> _init() async {
    // Request permission then load initial assets for the specific album
    bool perm = await _service.requestPermission();
    await _trashService.init();
    if (!perm) {
      return;
    }
    final media = await _service.getAllMedia(album: widget.album);
    // Filter out assets that are currently in the trash
    final filteredMedia = media.toList();
    setState(() {
      _photos = filteredMedia;
      _groupedItems = MediaService.groupPhotosByDate(filteredMedia);
      _loading = false;
    });
  }

  void _onGalleryChange(MethodCall call) {
    _init();
  }

  // Selection Logic
  // Toggles selection for a specific asset ID.
  // Updates UI to show selection circles and context bar.
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        // Deselect or exit selection mode if empty
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        // Add item to selection
        _selectedIds.add(id);
      }
    });
  }

  // Batch deletes all selected items by moving them to trash.
  Future<void> _deleteSelected() async {
    // Move all selected items to trash
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
    _init(); // Refresh list to reflect removal
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Moved selected items to trash")));
    }
  }

  Future<void> _shareSelected() async {
    // Share selected items using available platform methods
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

    // Listen for external gallery changes (e.g., new photos)
    PhotoManager.addChangeCallback(_onGalleryChange);
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onGalleryChange);
    _scrollController.dispose();
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
                  widget.album.name,
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
        body: Column(
          children: [
            FutureBuilder<int>(
              future: widget.album.assetCountAsync,
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
                        '${snapshot.data} items',
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
                padding: const EdgeInsets.all(5),
                child: ListView.builder(
                  cacheExtent: 1500,
                  itemCount: _groupedItems.length,
                  controller: _scrollController,
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
                              crossAxisSpacing: 3,
                              mainAxisSpacing: 3,
                            ),
                        itemCount: item.length,
                        itemBuilder: (context, index) {
                          final photo = item[index];
                          final globalIndex = _photos.indexOf(photo);
                          final isSelected = _selectedIds.contains(
                            photo.asset.id,
                          );

                          return GestureDetector(
                            onLongPress: () {
                              if (!_isSelecting) {
                                setState(() {
                                  _isSelecting = true;
                                });
                                _toggleSelection(photo.asset.id);
                              }
                            },
                            onTap: () async {
                              if (_isSelecting) {
                                _toggleSelection(photo.asset.id);
                              } else {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewerScreen(
                                      index: globalIndex,
                                      initialPhotos: _photos,
                                      sourceAlbums: widget.album,
                                    ),
                                  ),
                                );
                                // Update UI to reflect changes (e.g. favorites) without resetting scroll
                                setState(() {});
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
            ),
          ],
        ),
      ),
    );
  }
}
