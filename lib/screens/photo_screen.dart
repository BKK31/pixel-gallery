import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lumina_gallery/services/trash_service.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../services/media_service.dart';
import '../services/locked_folder_service.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../models/extensions/favourites_extension.dart';
import '../widgets/aves_entry_image.dart';
import '../screens/viewer_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/settings_service.dart';
import '../models/filters.dart';
import '../widgets/add_to_album_sheet.dart';

class PhotoScreen extends StatefulWidget {
  final AlbumModel album;

  const PhotoScreen({super.key, required this.album});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  List<dynamic> _groupedItems = [];

  final MediaService _service = MediaService();
  List<PhotoModel> _photos = [];
  bool _loading = true;

  final ScrollController _scrollController = ScrollController();

  final TrashService _trashService = TrashService();

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};
  StreamSubscription? _deleteSubscription;
  StreamSubscription? _albumSubscription;
  StreamSubscription? _updateSubscription;

  Future<void> refresh() => _init();

  // Initializes the screen by requesting permissions and loading initial assets.
  Future<void> _init() async {
    // Show cached data immediately if available
    if (_photos.isNotEmpty) {
      // Already have data, just refresh in background
      setState(() {
        _loading = false;
      });
    } else if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    // Non-blocking permission check and data load
    _service.requestPermission().then((perm) async {
      if (!perm) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      // Initialize trash service in background
      unawaited(_trashService.init());

      // 1. Initial Load from memory/DB cache
      final albums = await _service.getPhotos();

      if (!mounted) return;

      final latestAlbum = albums.firstWhere(
        (a) => a.id == widget.album.id,
        orElse: () => widget.album,
      );

      setState(() {
        _photos = latestAlbum.entries
            .map(
              (entry) => PhotoModel(
                uid: entry.id,
                asset: entry,
                timeTaken: entry.bestDate ?? DateTime.now(),
                isVideo: entry.isVideo,
              ),
            )
            .toList();
        _groupedItems = MediaService.groupPhotosByDate(_photos);
        _loading = false;
      });
    });

    // 2. Reactive listeners
    _updateSubscription?.cancel();
    _updateSubscription = _service.entryUpdateStream.listen((entry) {
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

    _deleteSubscription?.cancel();
    _deleteSubscription = _service.entryDeletedStream.listen((id) {
      if (!mounted) return;
      setState(() {
        _photos.removeWhere((p) => p.uid == id.toString());
        _groupedItems = MediaService.groupPhotosByDate(_photos);
      });
    });

    _albumSubscription?.cancel();
    _albumSubscription = _service.albumUpdateStream.listen((_) {
      _service.getPhotos().then((updatedAlbums) {
        if (!mounted) return;
        final updatedOne = updatedAlbums.firstWhere(
          (a) => a.id == widget.album.id,
          orElse: () => widget.album,
        );
        setState(() {
          _photos = updatedOne.entries
              .map(
                (entry) => PhotoModel(
                  uid: entry.id,
                  asset: entry,
                  timeTaken: entry.bestDate ?? DateTime.now(),
                  isVideo: entry.isVideo,
                ),
              )
              .toList();
          _groupedItems = MediaService.groupPhotosByDate(_photos);
        });
      });
    });
  }

  // Selection Logic
  // Toggles selection for a specific asset ID.
  // Updates UI to show selection circles and context bar.
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        // Deselect or exit selection mode if empty
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        // Add item to selection
        _selectedIds.add(id);
      }
    });
  }

  // Batch deletes all selected items with a confirmation dialog.
  Future<void> _deleteSelected() async {
    bool moveToTrash = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Delete items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Delete ${_selectedIds.length} selected item(s)?'),
              const SizedBox(height: 12),
              SwitchListTile(
                value: moveToTrash,
                onChanged: (v) => setStateDialog(() => moveToTrash = v),
                title: const Text('Move to bin'),
                subtitle: Text(
                  moveToTrash
                      ? 'Items can be restored from the recycle bin'
                      : 'Items will be permanently deleted',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                moveToTrash ? 'Move to bin' : 'Delete permanently',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    for (var id in _selectedIds) {
      final photo = _photos.cast<PhotoModel?>().firstWhere(
        (p) => p?.uid == id,
        orElse: () => null,
      );
      if (photo != null) {
        if (moveToTrash) {
          await _trashService.moveToTrash(photo.asset);
        } else {
          await _service.permanentlyDelete(photo.asset);
        }
      }
    }
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    _init();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            moveToTrash
                ? 'Moved selected items to trash'
                : 'Permanently deleted selected items',
          ),
        ),
      );
    }
  }

  Future<void> _shareSelected() async {
    List<XFile> files = [];
    for (var id in _selectedIds) {
      final photo = _photos.cast<PhotoModel?>().firstWhere(
        (p) => p?.uid == id,
        orElse: () => null,
      );
      if (photo != null) {
        final file = await photo.asset.file;
        if (file != null) files.add(XFile(file.path));
      }
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    }
    // Intentionally NOT clearing selection.
  }

  Future<void> _lockSelected() async {
    final lockedService = LockedFolderService();
    int successCount = 0;
    for (final id in List<String>.from(_selectedIds)) {
      final photo = _photos.cast<PhotoModel?>().firstWhere(
        (p) => p?.uid == id,
        orElse: () => null,
      );
      if (photo != null) {
        final ok = await lockedService.lock(photo.asset);
        if (ok) successCount++;
      }
    }
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    _init();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moved $successCount item(s) to Locked Folder')),
      );
    }
  }

  void _addToAlbumSelected() {
    final selectedPhotosList = _photos
        .where((p) => _selectedIds.contains(p.uid))
        .toList();
    AddToAlbumSheet.show(context, selectedPhotosList).then((_) {
      if (mounted && _isSelecting) {
        setState(() {
          _isSelecting = false;
          _selectedIds.clear();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _deleteSubscription?.cancel();
    _albumSubscription?.cancel();
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelecting) {
          setState(() {
            _isSelecting = false;
            _selectedIds.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBarM3E(
          title: _isSelecting
              ? Text(
                  "${_selectedIds.length} Selected",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  widget.album.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          centerTitle: false,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: _isSelecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelecting = false;
                      _selectedIds.clear();
                    });
                  },
                )
              : null,
          actions: _isSelecting
              ? [
                  IconButton(
                    onPressed: _shareSelected,
                    icon: const Icon(Icons.share),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteSelected();
                      } else if (value == 'lock') {
                        _lockSelected();
                      } else if (value == 'add_to_album') {
                        _addToAlbumSelected();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'lock',
                        child: ListTile(
                          leading: Icon(Icons.lock_outline),
                          title: Text('Move to Locked Folder'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_to_album',
                        child: ListTile(
                          leading: Icon(Icons.create_new_folder_outlined),
                          title: Text('Add to Album'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ]
              : [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'exclude') {
                        final hiddenFilters = SettingsService().hiddenFilters;
                        hiddenFilters.add(PathFilter(widget.album.id));
                        await SettingsService().setHiddenFilters(hiddenFilters);
                        MediaService().clearCache();
                        MediaService().rebuildAlbums();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Folder excluded')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'exclude',
                        child: Text('Exclude Folder'),
                      ),
                    ],
                  ),
                ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${widget.album.assetCount} items',
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
                      padding: const EdgeInsets.all(5),
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        interactive: true,
                        thickness: 8.0,
                        radius: const Radius.circular(4.0),
                        thumbColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        child: ListView.builder(
                          cacheExtent: 1500,
                          itemCount: _groupedItems.length,
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            final item = _groupedItems[index];

                            if (item is String) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1.5,
                                ),
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
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPhotoItem(PhotoModel photo) {
    final isSelected = _selectedIds.contains(photo.uid);

    return GestureDetector(
      onLongPress: () {
        if (!_isSelecting) {
          setState(() {
            _isSelecting = true;
          });
          _toggleSelection(photo.uid);
        }
      },
      onTap: () async {
        if (_isSelecting) {
          _toggleSelection(photo.uid);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewerScreen(
                index: photo.index ?? 0,
                initialPhotos: _photos,
                sourceAlbums: widget.album,
              ),
            ),
          );
          // Update UI to reflect changes (e.g. favorites) without resetting scroll
          setState(() {});
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
