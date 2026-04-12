import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lumina_gallery/services/trash_service.dart';
import '../services/media_service.dart';
import '../services/local_db.dart';
import '../services/locked_folder_service.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../models/extensions/favourites_extension.dart';
import '../widgets/aves_entry_image_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'video_screen.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:motion_photos/motion_photos.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import '../services/window_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ViewerScreen extends StatefulWidget {
  final int index;
  final List<PhotoModel> initialPhotos;
  final AlbumModel sourceAlbums;
  final bool canLoadMore;

  const ViewerScreen({
    super.key,
    required this.index,
    required this.initialPhotos,
    required this.sourceAlbums,
    this.canLoadMore = true,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _controller;
  int _currentIndex = 0;
  bool _showUI = true;
  late List<PhotoModel> _photos;
  Player? _player;
  VideoController? _videoKitController;

  // Features state
  bool _isMotionPhoto = false;
  bool _isPlayingMotion = false;
  bool _isAutoRotate = false;
  bool _isCurrentHdr = false;
  bool _isZoomed = false;
  final LocalDatabase _db = LocalDatabase();

  final List<String> _popupActions = ['Set as Wallpaper', 'Move to Locked Folder'];
  Player? _motionPlayer;
  VideoController? _motionVideoController;

  int _page = 0;

  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();
  StreamSubscription? _updateSubscription;
  Timer? _uiTimer;

  static const _platform = MethodChannel('com.pixel.gallery/open_file');

  Future<void> _loadMore() async {
    if (!widget.canLoadMore) return;
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
      _player?.dispose();
      _player = null;
      _videoKitController = null;
      return;
    }

    await _player?.dispose();
    _player = null;
    _videoKitController = null;

    try {
      final file = await photo.asset.file;
      if (file != null && await file.exists()) {
        final player = Player(
          configuration: const PlayerConfiguration(
            bufferSize: 64 * 1024 * 1024,
          ),
        );
        final controller = VideoController(
          player,
          configuration: const VideoControllerConfiguration(hwdec: 'auto-safe'),
        );

        await player.setVolume(100);
        await player.setPlaylistMode(PlaylistMode.loop);
        await player.open(Media(file.path), play: true);

        if (mounted && _currentIndex == index) {
          setState(() {
            _player = player;
            _videoKitController = controller;
          });
        } else {
          await player.dispose();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted && _showUI) {
        final photo = _photos[_currentIndex];
        bool shouldHide = false;
        if (photo.asset.isVideo) {
          if (_player?.state.playing == true) {
            shouldHide = true;
          }
        } else {
          shouldHide = true;
        }

        if (shouldHide) {
          setState(() {
            _showUI = false;
            _updateSystemUI();
          });
        }
      }
    });
  }

  void _resetUiTimer() {
    _uiTimer?.cancel();
    if (_showUI) {
      _startUiTimer();
    }
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      _updateSystemUI();
      if (_showUI) {
        _startUiTimer();
      } else {
        _uiTimer?.cancel();
      }
    });
  }

  Future<void> _checkMotionPhoto(int index) async {
    if (mounted) {
      setState(() {
        _isMotionPhoto = false;
        _isPlayingMotion = false;
        _motionPlayer?.dispose();
        _motionPlayer = null;
        _motionVideoController = null;
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

  Future<void> _playMotionVideo() async {
    if (!_isMotionPhoto) return;

    final photo = _photos[_currentIndex];
    final file = await photo.asset.file;
    if (file == null) return;

    try {
      final motionPhotos = MotionPhotos(file.path);
      final videoFile = await motionPhotos.getMotionVideoFile(
        await getTemporaryDirectory(),
      );

      _motionPlayer = Player();
      _motionVideoController = VideoController(_motionPlayer!);
      await _motionPlayer!.open(Media(videoFile.path));
      await _motionPlayer!.setPlaylistMode(PlaylistMode.loop);
      WakelockPlus.enable();

      if (mounted) {
        setState(() {
          _isPlayingMotion = true;
        });
      }
    } catch (e) {
      debugPrint("Error playing motion video: $e");
    }
  }

  void _stopMotionVideo() {
    _motionPlayer?.pause();
    WakelockPlus.disable();
    _motionPlayer?.dispose();
    _motionPlayer = null;
    _motionVideoController = null;
    if (mounted) {
      setState(() {
        _isPlayingMotion = false;
      });
    }
  }

  Future<void> _applyHdrMode(int index) async {
    final asset = _photos[index].asset;
    final isHdr = await _db.isHdr(asset.contentId);
    if (isHdr != _isCurrentHdr) {
      _isCurrentHdr = isHdr;
      await WindowService.setColorMode(wideColorGamut: isHdr, hdr: isHdr);
    }
  }

  Future<void> _autoRotate() async {
    if (!mounted) return;
    int sensorOrientation = await WindowService.getSensorOrientation();
    if (sensorOrientation == -1) return;

    if (sensorOrientation == WindowService.sensorLandscape) {
      WindowService.requestOrientation(WindowService.screenOrientationLandscape);
    } else if (sensorOrientation == WindowService.sensorReverseLandscape) {
      WindowService.requestOrientation(WindowService.screenOrientationReverseLandscape);
    } else {
      WindowService.requestOrientation(WindowService.screenOrientationUserPortrait);
    }
  }

  void _updateSystemUI() {
    if (_showUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _onPageChanged(int index) {
    _stopMotionVideo();
    if (mounted) {
      setState(() {
        _currentIndex = index;
        _isZoomed = false;
      });
    }
    _initializeVideoController(index);
    _checkMotionPhoto(index);
    _applyHdrMode(index);
    if (_isAutoRotate) {
      _autoRotate();
    }

    _startUiTimer();

    if (index >= _photos.length - 5) {
      _loadMore();
    }
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
    _applyHdrMode(widget.index);
    _updateSystemUI();

    _startUiTimer();

    _updateSubscription = _service.entryUpdateStream.listen((entry) {
      if (mounted) {
        setState(() {
          final index = _photos.indexWhere((p) => p.asset.contentId == entry.contentId);
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
    _player?.dispose();
    _motionPlayer?.dispose();
    _uiTimer?.cancel();
    WakelockPlus.disable();
    _updateSubscription?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WindowService.setColorMode(wideColorGamut: false, hdr: false);
    WindowService.requestOrientation(WindowService.screenOrientationUnspecified);
    super.dispose();
  }

  // --- Interaction Handlers ---

  Future<void> _toggleFavorite(PhotoModel photo) async {
    await _service.toggleFavorite(photo.asset);
    if (mounted) setState(() {});
  }

  Future<void> _sharePhoto(PhotoModel photo) async {
    final file = await photo.asset.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  Future<void> _editPhoto(PhotoModel photo) async {
    final file = await photo.asset.file;
    if (file != null) {
      try {
        await _platform.invokeMethod('editFile', {
          'path': file.path,
          'mimeType': photo.asset.sourceMimeType,
        });
      } catch (e) {
        debugPrint("Error launching edit: $e");
      }
    }
  }

  Future<void> _toggleLock(PhotoModel photo) async {
    final lockedService = LockedFolderService();
    final isLocked = lockedService.isLocked(photo.asset.contentId);

    if (isLocked) {
      final success = await lockedService.unlock(photo.asset);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.restoredToGallery)),
        );
        setState(() {});
      }
    } else {
      final success = await lockedService.lock(photo.asset);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.movedToLockedFolderSnackbar(1))),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deletePhoto(PhotoModel photo) async {
    bool moveToTrash = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.deletePhoto),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.deletePhotoDesc),
              const SizedBox(height: 12),
              SwitchListTile(
                value: moveToTrash,
                onChanged: (v) => setStateDialog(() => moveToTrash = v),
                title: Text(AppLocalizations.of(context)!.moveToBin),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                moveToTrash ? AppLocalizations.of(context)!.moveToBin : AppLocalizations.of(context)!.deletePermanently,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    if (moveToTrash) {
      await _trashService.moveToTrash(photo.asset);
    } else {
      await _service.permanentlyDelete(photo.asset);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = _photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main Content
          GestureDetector(
            onTap: _toggleUI,
            child: PhotoViewGallery.builder(
              scrollPhysics: _isZoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              pageController: _controller,
              onPageChanged: _onPageChanged,
              itemCount: _photos.length,
              builder: (context, index) {
                final photo = _photos[index];
                if (photo.asset.isVideo) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onTapUp: (_) => _toggleUI(),
                      behavior: HitTestBehavior.translucent,
                      child: VideoScreen(
                        asset: photo.asset,
                        controlsVisible: _showUI,
                        player: _player,
                        controller: _videoKitController,
                        onUserInteraction: _resetUiTimer,
                      ),
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained,
                    disableGestures: true,
                  );
                } else if (_isMotionPhoto && index == _currentIndex && _isPlayingMotion && _motionVideoController != null) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onTapUp: (_) => _toggleUI(),
                      behavior: HitTestBehavior.translucent,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(image: AvesEntryImageProvider(photo.asset), fit: BoxFit.contain),
                          Positioned.fill(
                            child: Center(child: Video(controller: _motionVideoController!, controls: NoVideoControls)),
                          ),
                        ],
                      ),
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained,
                    disableGestures: true,
                  );
                } else {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: PhotoView(
                      imageProvider: AvesEntryImageProvider(photo.asset),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      heroAttributes: PhotoViewHeroAttributes(tag: photo.asset.id),
                      onTapUp: (context, details, value) => _toggleUI(),
                      scaleStateChangedCallback: (state) {
                        if (mounted) {
                          setState(() {
                            _isZoomed = state != PhotoViewScaleState.initial;
                          });
                        }
                      },
                    ),
                  );
                }
              },
            ),
          ),


          // Top Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showUI ? 0 : -100,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (_isMotionPhoto)
                      IconButton(
                        icon: Icon(_isPlayingMotion ? Icons.motion_photos_pause : Icons.motion_photos_on, color: Colors.white),
                        onPressed: () => _isPlayingMotion ? _stopMotionVideo() : _playMotionVideo(),
                      ),
                    IconButton(
                      icon: Icon(
                        _isAutoRotate ? Icons.screen_rotation : Icons.screen_lock_rotation,
                        color: _isAutoRotate ? Theme.of(context).colorScheme.primary : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAutoRotate = !_isAutoRotate;
                          if (_isAutoRotate) {
                            _autoRotate();
                          } else {
                            WindowService.requestOrientation(WindowService.screenOrientationUnspecified);
                          }
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == _popupActions[0]) _showWallpaperOptions(currentPhoto);
                        if (value == _popupActions[1]) _toggleLock(currentPhoto);
                      },
                      itemBuilder: (context) => _popupActions.map((action) => PopupMenuItem(value: action, child: Text(action))).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showUI ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      currentPhoto.asset.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: currentPhoto.asset.isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () => _toggleFavorite(currentPhoto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => _editPhoto(currentPhoto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () => _showInfoBottomSheet(currentPhoto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () => _sharePhoto(currentPhoto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _deletePhoto(currentPhoto),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Future<void> _showInfoBottomSheet(PhotoModel photo) async {
    final updatedEntry = await _service.refreshEntry(photo.asset);
    final asset = updatedEntry ?? photo.asset;
    File? file = await asset.file;
    int? sizeBytes = await file?.length();
    String sizeStr = sizeBytes != null ? "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB" : "Unknown";

    Map<String, dynamic>? dbMetadata;
    Map<String, dynamic>? location;
    if (asset.contentId != null) {
      final metadataMap = await _db.loadMetadataByIds([asset.contentId!]);
      if (metadataMap.isNotEmpty) {
        dbMetadata = metadataMap[asset.contentId];
        if (dbMetadata?['latitude'] != null && dbMetadata?['longitude'] != null) {
          location = {'latitude': dbMetadata!['latitude'] as double, 'longitude': dbMetadata['longitude'] as double};
        }
      }
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.details, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(leading: const Icon(Icons.image), title: Text(photo.asset.title ?? "Unknown"), subtitle: Text("${photo.asset.width}x${photo.asset.height} • $sizeStr")),
              ListTile(leading: const Icon(Icons.calendar_today), title: Text(DateFormat.yMMMd().format(photo.timeTaken))),
              if (dbMetadata != null && (dbMetadata['make'] != null || dbMetadata['model'] != null)) ...[
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.cameraInfo, style: const TextStyle(fontWeight: FontWeight.bold)),
                ListTile(leading: const Icon(Icons.camera_alt), title: Text("${dbMetadata['make'] ?? ''} ${dbMetadata['model'] ?? ''}".trim())),
              ],
              if (location != null) ...[
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.location, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800)),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    options: MapOptions(initialCenter: latLng.LatLng(location['latitude'] as double, location['longitude'] as double), initialZoom: 15.0),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.pixel.gallery'),
                      MarkerLayer(markers: [Marker(point: latLng.LatLng(location['latitude'] as double, location['longitude'] as double), child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showWallpaperOptions(PhotoModel photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWallpaperTile(AppLocalizations.of(context)!.homeScreen, photo, WallpaperManagerPlus.homeScreen),
          _buildWallpaperTile(AppLocalizations.of(context)!.lockScreen, photo, WallpaperManagerPlus.lockScreen),
          _buildWallpaperTile(AppLocalizations.of(context)!.bothScreens, photo, WallpaperManagerPlus.bothScreens),
        ],
      ),
    );
  }

  Widget _buildWallpaperTile(String label, PhotoModel photo, int location) {
    return ListTile(
      leading: const Icon(Icons.wallpaper),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        final file = await photo.asset.file;
        if (file != null) await WallpaperManagerPlus().setWallpaper(file, location);
      },
    );
  }
}
