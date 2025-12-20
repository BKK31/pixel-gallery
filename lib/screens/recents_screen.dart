import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/photo_model.dart';
import 'package:lumina_gallery/screens/viewer_screen.dart';
import 'package:lumina_gallery/services/media_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

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

  late final ScrollController _scrollController = ScrollController();
  final MediaService _service = MediaService();

  Future<void> _init() async {
    bool perm = await _service.requestPermission();
    if (!perm) {
      return;
    }
    final albums = await _service.getPhotos();
    _currentAlbum = albums[0];
    final media = await _service.getMedia(album: _currentAlbum!, page: 0);
    setState(() {
      _photos = media;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_currentAlbum == null) return;
    _page++;
    final media = await _service.getMedia(album: _currentAlbum!, page: _page);
    setState(() {
      _photos.addAll(media);
    });
  }

  @override
  void initState() {
    super.initState();
    _init();

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scrollbar(
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
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewerScreen(
                    index: index,
                    photos: List.unmodifiable(_photos),
                  ),
                ),
              );
            },
            child: AssetEntityImage(
              photo.asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(180),
              thumbnailFormat: ThumbnailFormat.jpeg,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
