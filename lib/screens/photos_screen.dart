import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/photo_model.dart';
import 'package:lumina_gallery/screens/viewer_screen.dart';
import 'package:lumina_gallery/services/media_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<PhotoModel> _photos = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  late final ScrollController _scrollController = ScrollController();
  final MediaService _service = MediaService();

  Future<void> _init() async {
    await _service.init();
    final firstBatch = await _service.loadNextPage();

    setState(() {
      _photos = firstBatch;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    final more = await _service.loadNextPage();

    setState(() {
      _photos.addAll(more);
    });

    _loadingMore = false;
  }

  @override
  void initState() {
    super.initState();
    _init();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_loadingMore && _hasMore) {
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
              thumbnailSize: const ThumbnailSize(300, 300),
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
