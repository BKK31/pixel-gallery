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
import 'package:native_exif/native_exif.dart';
import 'package:motion_photos/motion_photos.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
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

  // Motion Photo state
  bool _isMotionPhoto = false;
  bool _isPlayingMotion = false;
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

    // Dispose old controller if exists
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

        // Only update if we're still on this index and viewer still mounted
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
      debugPrint('Error initializing video at index $index: $e');
    }
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _showUI && _player?.state.playing == true) {
        setState(() {
          _showUI = false;
        });
      }
    });
  }

  void _resetUiTimer() {
    _uiTimer?.cancel();
    if (_showUI && _player?.state.playing == true) {
      _startUiTimer();
    }
  }

  Future<void> _checkMotionPhoto(int index) async {
    // Reset state for new page
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
      debugPrint("Error playing video: $e");
    }
  }

  void _stopVideo() {
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

  Future<void> _toggleFavorite(PhotoModel photo) async {
    await _service.toggleFavorite(photo.asset);
    // Force UI update since isFavorite is a getter that reads from FavouritesManager
    if (mounted) {
      setState(() {});
    }
  }

  // Shows a confirmation dialog then deletes or moves to trash.
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
                subtitle: Text(
                  moveToTrash
                      ? AppLocalizations.of(context)!.moveToBinDesc
                      : AppLocalizations.of(context)!.deletePermanentlyDesc,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.movedToTrashSnackbar)));
      }
    } else {
      await _service.permanentlyDelete(photo.asset);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deletedPermanentlySnackbar)));
      }
    }

    Navigator.pop(context);
  }

  Future<void> _toggleLock(PhotoModel photo) async {
    final lockedService = LockedFolderService();
    final isLocked = lockedService.isLocked(photo.asset.contentId);

    if (isLocked) {
      final success = await lockedService.unlock(photo.asset);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? AppLocalizations.of(context)!.restoredToGallery
                : AppLocalizations.of(context)!.failedToRestore),
          ),
        );
        if (success) setState(() {});
      }
    } else {
      final success = await lockedService.lock(photo.asset);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? AppLocalizations.of(context)!.movedToLockedFolderSnackbar(1)
                : AppLocalizations.of(context)!.failedToMoveToLocked),
          ),
        );
        if (success) Navigator.pop(context);
      }
    }
  }

  Future<void> _sharePhoto(PhotoModel photo) async {
    File? file = await photo.asset.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  Future<void> _editPhoto(PhotoModel photo) async {
    File? file = await photo.asset.file;
    if (file != null) {
      try {
        await _platform.invokeMethod('editFile', {
          'path': file.path,
          'mimeType': photo.asset.sourceMimeType,
        });
      } on PlatformException catch (e) {
        debugPrint("Error launching edit: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchEditor)),
          );
        }
      }
    }
  }

  Future<void> _setWallpaper(PhotoModel photo, int location) async {
    File? file = await photo.asset.file;
    if (file == null) return;

    try {
      // Show loading indicator? Or just toast after
      await WallpaperManagerPlus().setWallpaper(file, location);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.wallpaperSetSuccess)),
        );
      }
    } catch (e) {
      debugPrint("Error setting wallpaper: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.wallpaperSetFailed)),
        );
      }
    }
  }

  void _showWallpaperOptions(PhotoModel photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: Text(AppLocalizations.of(context)!.homeScreen),
            onTap: () {
              Navigator.pop(context);
              _setWallpaper(photo, WallpaperManagerPlus.homeScreen);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(AppLocalizations.of(context)!.lockScreen),
            onTap: () {
              Navigator.pop(context);
              _setWallpaper(photo, WallpaperManagerPlus.lockScreen);
            },
          ),
          ListTile(
            leading: const Icon(Icons.smartphone),
            title: Text(AppLocalizations.of(context)!.bothScreens),
            onTap: () {
              Navigator.pop(context);
              _setWallpaper(photo, WallpaperManagerPlus.bothScreens);
            },
          ),
        ],
      ),
    );
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
        : AppLocalizations.of(context)!.unknown;

    final db = LocalDatabase();
    Map<String, dynamic>? dbMetadata;
    Map<String, dynamic>? location;
    if (asset.contentId != null) {
      final metadataMap = await db.loadMetadataByIds([asset.contentId!]);
      if (metadataMap.isNotEmpty) {
        dbMetadata = metadataMap[asset.contentId];
        if (dbMetadata?['latitude'] != null &&
            dbMetadata?['longitude'] != null) {
          location = {
            'latitude': dbMetadata!['latitude'] as double,
            'longitude': dbMetadata['longitude'] as double,
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

    // Slight delay to allow dismiss animation to settle if triggered by swipe
    await Future.delayed(const Duration(milliseconds: 100));

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
                Text(
                  AppLocalizations.of(context)!.details,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(photo.asset.title ?? AppLocalizations.of(context)!.unknown),
                  subtitle: Text(
                    "${photo.asset.width}x${photo.asset.height} • $sizeStr",
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat.yMMMd().format(photo.timeTaken)),
                ),
                if ((exifData != null && exifData.isNotEmpty) ||
                    (dbMetadata != null &&
                        (dbMetadata['make'] != null ||
                            dbMetadata['model'] != null))) ...[
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.cameraInfo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (exifData?['Model'] != null ||
                      exifData?['Make'] != null ||
                      dbMetadata?['make'] != null ||
                      dbMetadata?['model'] != null)
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: Text(
                        (exifData != null &&
                                (exifData['Make'] != null ||
                                    exifData['Model'] != null))
                            ? "${exifData['Make'] ?? ''} ${exifData['Model'] ?? ''}"
                                  .trim()
                            : "${dbMetadata?['make'] ?? ''} ${dbMetadata?['model'] ?? ''}"
                                  .trim(),
                      ),
                      subtitle: Text(AppLocalizations.of(context)!.camera),
                    ),
                  if (exifData != null &&
                      (exifData['FNumber'] != null ||
                          exifData['ExposureTime'] != null ||
                          exifData['ISOSpeedRatings'] != null))
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
                      subtitle: Text(AppLocalizations.of(context)!.exifSettings),
                    ),
                ],
                if (location != null &&
                    location['latitude'] != null &&
                    location['longitude'] != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.location,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                          location['latitude'] as double,
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
                                location['latitude'] as double,
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

    if (widget.initialPhotos[widget.index].asset.isVideo) {
      _startUiTimer();
    }

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
    _player?.dispose();
    _motionPlayer?.dispose();
    _uiTimer?.cancel();
    WakelockPlus.disable();
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
                if (_showUI) {
                  _resetUiTimer();
                }
              });
            },
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _controller,
              onPageChanged: (index) {
                _stopVideo(); // Stop any playing motion video
                if (mounted) {
                  setState(() {
                    _currentIndex = index;
                  });
                }
                _initializeVideoController(index);
                _checkMotionPhoto(index);

                if (_photos[index].asset.isVideo) {
                  _startUiTimer();
                } else {
                  _uiTimer?.cancel();
                }

                if (index >= _photos.length - 5) {
                  _loadMore();
                }
              },
              itemCount: _photos.length,
              builder: (context, index) {
                final photo = _photos[index];

                if (photo.asset.isVideo) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: VideoScreen(
                      asset: photo.asset,
                      controlsVisible: _showUI,
                      player: _player,
                      controller: _videoKitController,
                      onUserInteraction: _resetUiTimer,
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained,
                    disableGestures: true,
                  );
                } else {
                  if (index == _currentIndex &&
                      _isPlayingMotion &&
                      _motionVideoController != null) {
                    return PhotoViewGalleryPageOptions.customChild(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            image: AvesEntryImageProvider(photo.asset),
                            fit: BoxFit.contain,
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Video(
                                controller: _motionVideoController!,
                                controls: NoVideoControls,
                              ),
                            ),
                          ),
                        ],
                      ),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.contained,
                      disableGestures: true,
                    );
                  }

                  return PhotoViewGalleryPageOptions(
                    imageProvider: AvesEntryImageProvider(photo.asset),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: photo.asset.id,
                    ),
                  );
                }
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
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _showInfoBottomSheet(_photos[_currentIndex]);
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'wallpaper') {
                        _showWallpaperOptions(_photos[_currentIndex]);
                      } else if (value == 'lock') {
                        _toggleLock(_photos[_currentIndex]);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final isLocked = LockedFolderService().isLocked(
                        _photos[_currentIndex].asset.contentId,
                      );
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'wallpaper',
                          child: Text(AppLocalizations.of(context)!.setAsWallpaper),
                        ),
                        PopupMenuItem<String>(
                          value: 'lock',
                          child: Text(
                            isLocked
                                ? AppLocalizations.of(context)!.removeFromLockedFolder
                                : AppLocalizations.of(context)!.moveToLockedFolder,
                          ),
                        ),
                      ];
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
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _editPhoto(_photos[_currentIndex]);
                      },
                    ),
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
