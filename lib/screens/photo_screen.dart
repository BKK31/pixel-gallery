import 'package:flutter/material.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../services/media_service.dart';
import '../models/photo_model.dart';
import 'package:intl/intl.dart';
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
  int _page = 0;
  bool _isLoadingMore = false;

  final TrashService _trashService = TrashService();

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  Future<void> _init() async {
    // Request permission then load initial assets for the specific album
    bool perm = await _service.requestPermission();
    await _trashService.init();
    if (!perm) {
      return;
    }
    final media = await _service.getMedia(album: widget.album, page: 0);
    // Filter out assets that are currently in the trash
    final filteredMedia = media
        .where((p) => !_trashService.isTrashed(p.asset.id))
        .toList();
    setState(() {
      _photos = filteredMedia;
      _groupedItems = _groupedPhotos(filteredMedia);
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    // Load next page of assets and append to the list
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    _page++;

    final media = await _service.getMedia(album: widget.album, page: _page);
    final filteredMedia = media
        .where((p) => !_trashService.isTrashed(p.asset.id))
        .toList();

    if (media.isNotEmpty) {
      setState(() {
        _photos.addAll(filteredMedia);
        _groupedItems = _groupedPhotos(_photos);
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  List<dynamic> _groupedPhotos(List<PhotoModel> photos) {
    // Group photos by date to display date headers
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

  void _onGalleryChange(MethodCall call) {
    _init();
  }

  // Selection Logic
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

  Future<void> _deleteSelected() async {
    // Move all selected items to trash
    for (var id in _selectedIds) {
      await _trashService.moveToTrash(id);
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

    _scrollController.addListener(() {
      // Infinite scroll listener
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onGalleryChange);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelecting
            ? Text("${_selectedIds.length} Selected")
            : Text(widget.album.name),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isSelecting
            ? IconButton(
                icon: Icon(Icons.close),
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
                IconButton(onPressed: _shareSelected, icon: Icon(Icons.share)),
                IconButton(
                  onPressed: _deleteSelected,
                  icon: Icon(Icons.delete),
                ),
              ]
            : [],
      ),
      body: ListView.builder(
        itemCount: _groupedItems.length,
        controller: _scrollController,
        itemBuilder: (context, index) {
          final item = _groupedItems[index];

          if (item is String) {
            return Container(
              padding: EdgeInsets.all(12),
              child: Text(
                item,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          } else if (item is List<PhotoModel>) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: item.length,
              itemBuilder: (context, index) {
                final photo = item[index];
                final globalIndex = _photos.indexOf(photo);
                final isSelected = _selectedIds.contains(photo.asset.id);

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
                      _init();
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetEntityImage(
                        photo.asset,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(200),
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
        },
      ),
    );
  }
}
