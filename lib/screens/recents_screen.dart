import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/photo_model.dart';
import 'package:lumina_gallery/screens/viewer_screen.dart';
import 'package:lumina_gallery/services/media_service.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  List<PhotoModel> _photos = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  AssetPathEntity? _currentAlbum;

  // Selection State
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  late final ScrollController _scrollController = ScrollController();
  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();

  Future<void> _init() async {
    bool perm = await _service.requestPermission();
    await _trashService.init();
    if (!perm) {
      return;
    }
    final albums = await _service.getPhotos();
    _currentAlbum = albums[0];
    final media = await _service.getMedia(album: _currentAlbum!, page: 0);
    final filteredMedia = media
        .where((p) => !_trashService.isTrashed(p.asset.id))
        .toList();
    setState(() {
      _photos = filteredMedia;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_currentAlbum == null) return;
    _page++;
    final media = await _service.getMedia(album: _currentAlbum!, page: _page);
    final filteredMedia = media
        .where((p) => !_trashService.isTrashed(p.asset.id))
        .toList();

    setState(() {
      _photos.addAll(filteredMedia);
    });
  }

  void _onGalleryChange(MethodCall call) {
    _init();
  }

  // Selection Logic
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    for (var id in _selectedIds) {
      await _trashService.moveToTrash(id);
    }
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    _init(); // Refresh list

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Moved selected items to trash")));
    }
  }

  Future<void> _shareSelected() async {
    List<XFile> files = [];
    for (var id in _selectedIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        final file = await asset.file;
        if (file != null) {
          files.add(XFile(file.path));
        }
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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_loadingMore &&
          _hasMore) {
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: _isSelecting
          ? AppBar(
              title: Text("${_selectedIds.length} Selected"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelecting = false;
                    _selectedIds.clear();
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : null, // No AppBar when not selecting (handled by Home)
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemCount: _photos.length,
          itemBuilder: (context, index) {
            final photo = _photos[index];
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
                        index: index,
                        initialPhotos: List.unmodifiable(_photos),
                        sourceAlbums: _currentAlbum!,
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
        ),
      ),
    );
  }
}
