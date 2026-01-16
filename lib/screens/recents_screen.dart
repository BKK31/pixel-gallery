import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/photo_model.dart';
import 'package:lumina_gallery/models/extensions/favourites_extension.dart';
import 'package:lumina_gallery/screens/viewer_screen.dart';
import 'package:lumina_gallery/services/media_service.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import 'package:lumina_gallery/models/album_model.dart';
import 'package:lumina_gallery/widgets/aves_entry_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

class RecentsScreen extends StatefulWidget {
  final Function(bool, int)? onSelectionChanged;

  const RecentsScreen({super.key, this.onSelectionChanged});

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
  AlbumModel? _currentAlbum;

  bool _loading = true;
  bool _isSelecting = false;
  bool _isInitializing = false;
  final Set<String> _selectedIds = {};

  StreamSubscription? _updateSubscription;
  StreamSubscription? _deleteSubscription;
  StreamSubscription? _albumSubscription;
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  Future<void> refresh() => _init();

  Future<void> _init({bool silent = false}) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      if (!silent && mounted) {
        setState(() {
          _loading = true;
        });
      }

      final perm = await _service.requestPermission();
      await _trashService.init();
      await _trashService.requestPermission();

      if (!perm) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      // 1. Initial Load from memory/DB cache
      final albums = await _service.getPhotos();
      final recentAlbum = albums.firstWhere(
        (a) => a.id == 'recent',
        orElse: () => albums.first,
      );

      _processAlbum(recentAlbum);

      // 2. Setup reactive listeners (only once)
      _updateSubscription ??= _service.entryUpdateStream.listen((entry) {
        if (!mounted) return;
        final index = _photos.indexWhere((p) => p.uid == entry.id);
        if (index != -1) {
          setState(() {
            _photos[index] = PhotoModel(
              uid: entry.id,
              asset: entry,
              timeTaken: entry.bestDate ?? DateTime.now(),
              isVideo: entry.isVideo,
            );
            _groupedItems = MediaService.groupPhotosByDate(_photos);
          });
        }
      });

      _deleteSubscription ??= _service.entryDeletedStream.listen((id) {
        if (!mounted) return;
        setState(() {
          _photos.removeWhere((p) => p.uid == id.toString());
          _groupedItems = MediaService.groupPhotosByDate(_photos);
        });
      });

      _albumSubscription ??= _service.albumUpdateStream.listen((_) {
        _onAlbumUpdated();
      });

      // 3. Start background sync (if not already running)
      unawaited(_service.getMediaStream().drain());
    } finally {
      _isInitializing = false;
    }
  }

  void _onAlbumUpdated() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _init(silent: true);
      }
    });
  }

  void _processAlbum(AlbumModel album) {
    if (!mounted) return;
    setState(() {
      _currentAlbum = album;
      _photos = album.entries
          .map(
            (entry) => PhotoModel(
              uid: entry.id,
              asset: entry,
              timeTaken: entry.bestDate ?? DateTime.now(),
              isVideo: entry.isVideo,
            ),
          )
          .toList();
      _photos.sort((a, b) => b.timeTaken.compareTo(a.timeTaken));
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
      final photo = _photos.cast<PhotoModel?>().firstWhere(
        (p) => p?.uid == id,
        orElse: () => null,
      );
      if (photo != null) {
        await _trashService.moveToTrash(photo.asset);
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
      final photo = _photos.cast<PhotoModel?>().firstWhere(
        (p) => p?.uid == id,
        orElse: () => null,
      );
      if (photo != null) {
        final file = await photo.asset.file;
        if (file != null) {
          files.add(XFile(file.path));
        }
      }
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    }
    clearSelections();
  }

  List<int> getVisibleEntryIds() {
    return _photos
        .take(40)
        .map((p) => p.asset.contentId)
        .whereType<int>()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _updateSubscription?.cancel();
    _deleteSubscription?.cancel();
    _albumSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_photos.length} photos',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ListView.builder(
              cacheExtent: 1500,
              controller: _scrollController,
              itemCount: _groupedItems.length,
              itemBuilder: (context, index) {
                final item = _groupedItems[index];

                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                } else if (item is List<PhotoModel>) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Row(
                      children: [
                        for (int i = 0; i < 4; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: i < item.length
                                  ? _buildPhotoItem(item[i])
                                  : const SizedBox.shrink(),
                            ),
                          ),
                      ],
                    ),
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

  Widget _buildPhotoItem(PhotoModel photo) {
    final isSelected = _selectedIds.contains(photo.uid);

    return GestureDetector(
      onLongPress: () => _toggleSelection(photo.uid),
      onTap: () async {
        if (_isSelecting) {
          _toggleSelection(photo.uid);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewerScreen(
                index: photo.index ?? 0,
                initialPhotos: List.unmodifiable(_photos),
                sourceAlbums: _currentAlbum!,
              ),
            ),
          );
          if (mounted) setState(() {});
        }
      },
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AvesEntryImage(entry: photo.asset, extent: 200, fit: BoxFit.cover),
            if (isSelected)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Icon(Icons.check_circle, color: Colors.blue, size: 30),
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
            if (photo.asset.isFavorite && !isSelected)
              const Positioned(
                top: 5,
                right: 5,
                child: Icon(Icons.favorite, color: Colors.red, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
