import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import '../services/media_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'video_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:native_exif/native_exif.dart';

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
  bool _isZoomed = false;
  VideoPlayerController? _videoController;

  int _page = 0;

  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();

  Future<void> _loadMore() async {
    _page++;
    final media = await _service.getMedia(
      album: widget.sourceAlbums,
      page: _page,
    );
    setState(() {
      _photos.addAll(media);
    });
  }

  Future<void> _initializeVideoController(int index) async {
    _videoController?.dispose();
    _videoController = null;

    final photo = _photos[index];
    if (photo.asset.type == AssetType.video) {
      final file = await photo.asset.file;
      if (file != null) {
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        await _videoController!.setLooping(true);
        if (_currentIndex == index) {
          await _videoController!.play();
          setState(() {});
        }
      }
    }
  }

  // Toggles the favorite status of the current photo.
  // Performs the actual update via PhotoManager and refreshes the UI.
  Future<void> _toggleFavorite(PhotoModel photo) async {
    final bool oldStatus = photo.asset.isFavorite;
    final bool newStatus = !oldStatus;

    if (Platform.isAndroid) {
      await PhotoManager.editor.android.favoriteAsset(
        entity: photo.asset,
        favorite: newStatus,
      );
    }

    final newAsset = await AssetEntity.fromId(photo.asset.id);
    if (newAsset != null) {
      photo.asset = newAsset;
    }

    setState(() {});
  }

  // Moves the current photo to the trash and closes the viewer.
  // Shows a snackbar confirmation.
  Future<void> _deletePhoto(PhotoModel photo) async {
    await _trashService.moveToTrash(photo.asset);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Moved to trash")));
    }

    Navigator.pop(context);
  }

  Future<void> _sharePhoto(PhotoModel photo) async {
    File? file = await photo.asset.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  // Shows a bottom sheet with detailed metadata (EXIF) about the photo.
  // Reads file size, dimensions, camera info, and location if available.
  Future<void> _showInfoBottomSheet(PhotoModel photo) async {
    File? file = await photo.asset.file;
    int? sizeBytes = await file?.length();
    String sizeStr = sizeBytes != null
        ? "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB"
        : "Unknown";

    final location = await photo.asset.latlngAsync();

    Map<String, Object>? exifData;
    try {
      if (file != null) {
        final exif = await Exif.fromPath(file.path);
        exifData = await exif.getAttributes();
        await exif.close();
      }
    } catch (e) {
      debugPrint("Error reading EXIF: $e");
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
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
                if (exifData != null && exifData.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    "Camera Info",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  if (exifData['Model'] != null || exifData['Make'] != null)
                    ListTile(
                      leading: Icon(Icons.camera_alt),
                      title: Text(
                        "${exifData['Make'] ?? ''} ${exifData['Model'] ?? ''}"
                            .trim(),
                      ),
                      subtitle: Text("Camera"),
                    ),
                  if (exifData['FNumber'] != null ||
                      exifData['ExposureTime'] != null ||
                      exifData['ISOSpeedRatings'] != null)
                    ListTile(
                      leading: Icon(Icons.camera),
                      title: Text(
                        [
                          if (exifData['FNumber'] != null)
                            "ƒ/${exifData['FNumber']}",
                          if (exifData['ExposureTime'] != null)
                            "${exifData['ExposureTime']}s",
                          if (exifData['ISOSpeedRatings'] != null)
                            "ISO ${exifData['ISOSpeedRatings']}",
                        ].join(" • "),
                      ),
                      subtitle: Text("Settings"),
                    ),
                ],
                if (location != null &&
                    location.latitude != 0 &&
                    location.longitude != 0) ...[
                  SizedBox(height: 20),
                  Text(
                    "Location",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: latLng.LatLng(
                          location.latitude,
                          location.longitude,
                        ),
                        initialZoom: 15.0,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.pixel.gallery',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latLng.LatLng(
                                location.latitude,
                                location.longitude,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
    _initializeVideoController(widget.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
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
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _initializeVideoController(index);
                if (index >= _photos.length - 5) {
                  _loadMore();
                }
              },
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];

                if (photo.asset.type == AssetType.video) {
                  return VideoScreen(
                    asset: photo.asset,
                    controlsVisible: _showUI,
                    videoController: _videoController,
                  );
                }

                return PhotoView(
                  scaleStateChangedCallback: (state) {
                    setState(() {
                      _isZoomed = state != PhotoViewScaleState.initial;
                    });
                  },
                  imageProvider: AssetEntityImageProvider(
                    photo.asset,
                    isOriginal: true,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: photo.asset.id,
                  ),
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
                padding: EdgeInsets.only(
                  top: 10,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 10,
                ),
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
