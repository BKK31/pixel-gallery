import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import '../services/media_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'video_screen.dart';

class ViewerScreen extends StatefulWidget {
  final int index;
  final List<PhotoModel> initialPhotos;
  final AssetPathEntity sourceAlbums;

  const ViewerScreen({
    super.key,
    required this.index,
    required this.initialPhotos,
    required this.sourceAlbums,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _controller;
  int _currentIndex = 0;
  bool _showUI = true;
  late List<PhotoModel> _photos;

  int _page = 0;

  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();

  Future<void> _loadMore() async {
    // Load more photos from the service when reaching the end of the list
    _page++;
    final media = await _service.getMedia(
      album: widget.sourceAlbums,
      page: _page,
    );
    setState(() {
      _photos.addAll(media);
    });
  }

  Future<void> _toggleFavorite(PhotoModel photo) async {
    // Toggle the favorite status of the photo using PhotoManager
    final bool oldStatus = photo.asset.isFavorite;
    final bool newStatus = !oldStatus;

    if (Platform.isAndroid) {
      await PhotoManager.editor.android.favoriteAsset(
        entity: photo.asset,
        favorite: newStatus,
      );
    }

    // Refresh asset state
    final newAsset = await AssetEntity.fromId(photo.asset.id);
    if (newAsset != null) {
      photo.asset = newAsset;
    }

    setState(() {});
  }

  Future<void> _deletePhoto(PhotoModel photo) async {
    // Move the photo to trash and provide an undo option
    await _trashService.moveToTrash(photo.asset.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Moved to trash"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            await _trashService.restore(photo.asset.id);
            setState(() {});
          },
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _sharePhoto(PhotoModel photo) async {
    // Share the photo using the system share sheet
    File? file = await photo.asset.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  Future<void> _showInfoBottomSheet(PhotoModel photo) async {
    // Display file details in a bottom sheet
    File? file = await photo.asset.file;
    int? sizeBytes = await file?.length();
    String sizeStr = sizeBytes != null
        ? "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB"
        : "Unknown";

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.image),
                title: Text(photo.asset.title ?? "Unknown"),
                subtitle: Text(
                  "${photo.asset.width}x${photo.asset.height} • $sizeStr",
                ),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text(DateFormat.yMMMd().format(photo.timeTaken)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _trashService.init();
    _currentIndex = widget.index;
    _photos = List.from(widget.initialPhotos);
    _controller = PageController(initialPage: widget.index);
    _page = (widget.initialPhotos.length / 50).ceil() - 1;
    if (_page < 0) _page = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showUI = !_showUI;
              });
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                // Auto-load more photos when nearing the end
                if (index >= _photos.length - 5) {
                  _loadMore();
                }
              },
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];

                if (photo.asset.type == AssetType.video) {
                  return VideoScreen(
                    videoFile: photo.asset,
                    controlsVisible: _showUI,
                  );
                }

                return PhotoView(
                  imageProvider: AssetEntityImageProvider(
                    photo.asset,
                    isOriginal: true,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  heroAttributes: PhotoViewHeroAttributes(tag: photo.asset.id),
                );
              },
            ),
          ),

          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.5),
                iconTheme: IconThemeData(color: Colors.white),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () {
                      final photo = _photos[_currentIndex];
                      _showInfoBottomSheet(photo);
                    },
                  ),
                ],
              ),
            ),

          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                margin: EdgeInsets.only(bottom: 15),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        _sharePhoto(_photos[_currentIndex]);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _photos[_currentIndex].asset.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _photos[_currentIndex].asset.isFavorite
                            ? Colors.red
                            : Colors.white,
                      ),
                      onPressed: () {
                        _toggleFavorite(_photos[_currentIndex]);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () {
                        _deletePhoto(_photos[_currentIndex]);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
