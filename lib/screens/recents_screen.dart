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

class RecentsScreenState extends State<RecentsScreen> {
  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();
  final ScrollController _scrollController = ScrollController();

  List<PhotoModel> _photos = [];
  AssetPathEntity? _currentAlbum;

  bool _loading = true;
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  int _page = 0;
  bool _isLoadingMore = false;

  Future<void> _init() async {
    final perm = await _service.requestPermission();
    await _trashService.init();
    await _trashService.requestPermission();

    if (!perm) return;

    _page = 0;
    final albums = await _service.getPhotos();
    _currentAlbum = albums.first;

    final media = await _service.getMedia(album: _currentAlbum!, page: 0);

    setState(() {
      _photos = media.toList();
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    _page++;

    final media = await _service.getMedia(album: _currentAlbum!, page: _page);

    if (media.isNotEmpty) {
      setState(() {
        _photos.addAll(media);
      });
    }

    setState(() {
      _isLoadingMore = false;
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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback((_) {});
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
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
                      index: index,
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
      ),
    );
  }
}
