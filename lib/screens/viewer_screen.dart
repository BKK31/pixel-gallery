import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import '../services/media_service.dart';
import '../services/local_db.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../models/extensions/favourites_extension.dart';
import '../widgets/aves_entry_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'video_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:native_exif/native_exif.dart';
import 'package:motion_photos/motion_photos.dart';

class ViewerScreen extends StatefulWidget {
  final int index;
  final List<PhotoModel> initialPhotos;
  final AlbumModel sourceAlbums;

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

  // Motion Photo state
  bool _isMotionPhoto = false;
  bool _isPlayingMotion = false;
  VideoPlayerController? _motionController;

  int _page = 0;

  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();
  StreamSubscription? _updateSubscription;

  Future<void> _loadMore() async {
    _page++;
    final media = await _service.getMedia(
      album: widget.sourceAlbums,
      page: _page,
    );
    if (mounted) {
      setState(() {
        _photos.addAll(media);
      });
    }
  }

  Future<void> _initializeVideoController(int index) async {
    if (index >= _photos.length) return;

    final photo = _photos[index];
    if (!photo.asset.isVideo) {
      _videoController?.dispose();
      _videoController = null;
      return;
    }

    // Dispose old controller if exists
    await _videoController?.dispose();
    _videoController = null;

    try {
      final file = await photo.asset.file;
      if (file != null && await file.exists()) {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        await controller.setLooping(true);

        // Only update if we're still on this index and viewer still mounted
        if (mounted && _currentIndex == index) {
          setState(() {
            _videoController = controller;
          });
          await controller.play();
        } else {
          await controller.dispose();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video at index $index: $e');
    }
  }

  Future<void> _checkMotionPhoto(int index) async {
    // Reset state for new page
    if (mounted) {
      setState(() {
        _isMotionPhoto = false;
        _isPlayingMotion = false;
        _motionController?.dispose();
        _motionController = null;
      });
    }

    final photo = _photos[index];
    if (photo.asset.isVideo) return;

    File? file = await photo.asset.file;
    if (file != null) {
      bool isMotion = false;
      try {
        final motionPhotos = MotionPhotos(file.path);
        isMotion = await motionPhotos.isMotionPhoto();
      } catch (e) {
        debugPrint("Error checking motion photo: $e");
      }

      if (mounted && _currentIndex == index) {
        setState(() {
          _isMotionPhoto = isMotion;
        });
      }
    }
  }

  Future<void> _playVideo() async {
    if (!_isMotionPhoto) return;

    final photo = _photos[_currentIndex];
    final file = await photo.asset.file;
    if (file == null) return;

    try {
      final motionPhotos = MotionPhotos(file.path);
      final videoFile = await motionPhotos.getMotionVideoFile(
        await getTemporaryDirectory(),
      );

      _motionController = VideoPlayerController.file(videoFile);
      await _motionController!.initialize();
      await _motionController!.setLooping(true);
      await _motionController!.play();

      if (mounted) {
        setState(() {
          _isPlayingMotion = true;
        });
      }
    } catch (e) {
      debugPrint("Error playing video: $e");
    }
  }

  void _stopVideo() {
    _motionController?.pause();
    _motionController?.dispose();
    _motionController = null;
    if (mounted) {
      setState(() {
        _isPlayingMotion = false;
      });
    }
  }

  Future<void> _toggleFavorite(PhotoModel photo) async {
    await _service.toggleFavorite(photo.asset);
  }

  // Moves the current photo to the trash and closes the viewer.
  // Shows a snackbar confirmation.
  Future<void> _deletePhoto(PhotoModel photo) async {
    await _trashService.moveToTrash(photo.asset);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Moved to trash")));
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
    // Refresh entry from DB to get latest cataloged metadata (e.g. lat/long)
    final updatedEntry = await _service.refreshEntry(photo.asset);
    final asset = updatedEntry ?? photo.asset;

    File? file = await asset.file;
    int? sizeBytes = await file?.length();
    String sizeStr = sizeBytes != null
        ? "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB"
        : "Unknown";

    // Load metadata from database to get lat/long
    final db = LocalDatabase();
    Map<String, dynamic>? location;
    if (asset.contentId != null) {
      final metadata = await db.loadMetadataByIds([asset.contentId!]);
      if (metadata.isNotEmpty) {
        final latLongData = metadata[asset.contentId];
        if (latLongData?['latitude'] != null &&
            latLongData?['longitude'] != null) {
          location = {
            'latitude': latLongData!['latitude'] as double,
            'longitude': latLongData['longitude'] as double,
          };
        }
      }
    }

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
      shape: const RoundedRectangleBorder(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(photo.asset.title ?? "Unknown"),
                  subtitle: Text(
                    "${photo.asset.width}x${photo.asset.height} • $sizeStr",
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat.yMMMd().format(photo.timeTaken)),
                ),
                if (exifData != null && exifData.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Camera Info",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (exifData['Model'] != null || exifData['Make'] != null)
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: Text(
                        "${exifData['Make'] ?? ''} ${exifData['Model'] ?? ''}"
                            .trim(),
                      ),
                      subtitle: const Text("Camera"),
                    ),
                  if (exifData['FNumber'] != null ||
                      exifData['ExposureTime'] != null ||
                      exifData['ISOSpeedRatings'] != null)
                    ListTile(
                      leading: const Icon(Icons.camera),
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
                      subtitle: const Text("Settings"),
                    ),
                ],
                if (location != null &&
                    location['latitude'] != null &&
                    location['longitude'] != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Location",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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
                          location!['latitude'] as double,
                          location['longitude'] as double,
                        ),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
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
                                location!['latitude'] as double,
                                location['longitude'] as double,
                              ),
                              child: const Icon(
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
    _checkMotionPhoto(widget.index);

    _updateSubscription = _service.entryUpdateStream.listen((entry) {
      if (mounted) {
        setState(() {
          final index = _photos.indexWhere(
            (p) => p.asset.contentId == entry.contentId,
          );
          if (index != -1) {
            _photos[index] = PhotoModel(
              uid: entry.id,
              asset: entry,
              timeTaken: entry.bestDate ?? DateTime.now(),
              isVideo: entry.isVideo,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
    _motionController?.dispose();
    _updateSubscription?.cancel();
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
                _stopVideo(); // Stop any playing motion video
                if (mounted) {
                  setState(() {
                    _currentIndex = index;
                  });
                }
                _initializeVideoController(index);
                _checkMotionPhoto(index);
                if (index >= _photos.length - 5) {
                  _loadMore();
                }
              },
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];

                if (photo.asset.isVideo) {
                  return VideoScreen(
                    asset: photo.asset,
                    controlsVisible: _showUI,
                    videoController: _videoController,
                  );
                }

                // Stack Logic: Photo is base, Video is overlay for Motion Photos
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoView(
                      scaleStateChangedCallback: (state) {
                        setState(() {
                          _isZoomed = state != PhotoViewScaleState.initial;
                        });
                      },
                      imageProvider: AvesEntryImageProvider(photo.asset),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: photo.asset.id,
                      ),
                    ),
                    if (index == _currentIndex &&
                        _isPlayingMotion &&
                        _motionController != null &&
                        _motionController!.value.isInitialized)
                      Positioned.fill(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _motionController!.value.aspectRatio,
                            child: VideoPlayer(_motionController!),
                          ),
                        ),
                      ),
                  ],
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
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (_isMotionPhoto)
                    IconButton(
                      icon: Icon(
                        _isPlayingMotion
                            ? Icons.motion_photos_pause
                            : Icons.motion_photos_on,
                      ),
                      onPressed: () {
                        if (_isPlayingMotion) {
                          _stopVideo();
                        } else {
                          _playVideo();
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
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
                      icon: const Icon(Icons.share, color: Colors.white),
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
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
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
