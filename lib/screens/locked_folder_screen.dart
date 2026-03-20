import 'package:flutter/material.dart';
import 'dart:async';
import '../services/media_service.dart';
import '../services/locked_folder_service.dart';
import '../services/biometric_service.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../widgets/aves_entry_image.dart';
import 'viewer_screen.dart';

class LockedFolderScreen extends StatefulWidget {
  const LockedFolderScreen({super.key});

  @override
  State<LockedFolderScreen> createState() => _LockedFolderScreenState();
}

class _LockedFolderScreenState extends State<LockedFolderScreen> {
  final MediaService _mediaService = MediaService();
  final LockedFolderService _lockedService = LockedFolderService();
  final BiometricService _bioService = BiometricService();

  List<PhotoModel> _photos = [];
  List<dynamic> _groupedItems = [];
  bool _loading = true;
  bool _authenticated = false;
  bool _isProcessing = false;

  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final available = await _bioService.isAvailable();
    if (!available) {
      _authenticated = true;
      _loadMedia();
      return;
    }

    final success = await _bioService.authenticate();
    if (success) {
      _authenticated = true;
      _loadMedia();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _loadMedia() {
    final photos = _mediaService.getLockedFolderMedia();
    photos.sort((a, b) {
      final c =
          (b.asset.bestDateMillis ?? 0).compareTo(a.asset.bestDateMillis ?? 0);
      if (c != 0) return c;
      return (b.asset.contentId ?? 0).compareTo(a.asset.contentId ?? 0);
    });
    for (int i = 0; i < photos.length; i++) {
      photos[i].index = i;
    }
    if (mounted) {
      setState(() {
        _photos = photos;
        _groupedItems = MediaService.groupPhotosByDate(photos);
        _loading = false;
      });
    }
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
  }

  void _clearSelections() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
  }

  Future<void> _unlockSelected() async {
    final entriesToUnlock = _photos
        .where((p) => _selectedIds.contains(p.uid))
        .map((p) => p.asset)
        .toList();

    setState(() => _isProcessing = true);
    await _lockedService.unlockAll(entriesToUnlock);
    setState(() => _isProcessing = false);

    _clearSelections();
    _loadMedia();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${entriesToUnlock.length} item(s) restored to gallery',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelecting) {
          _clearSelections();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSelecting
              ? Text('${_selectedIds.length} Selected')
              : const Text('Locked Folder'),
          leading: _isSelecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelections,
                )
              : null,
          actions: _isSelecting
              ? [
                  IconButton(
                    icon: const Icon(Icons.lock_open),
                    tooltip: 'Restore to gallery',
                    onPressed: _isProcessing ? null : _unlockSelected,
                  ),
                ]
              : [],
        ),
        body: Stack(
          children: [
            if (!_authenticated)
              const Center(child: CircularProgressIndicator())
            else if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_photos.isEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No locked items',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Move photos here from the viewer to hide them behind biometric lock',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDisclaimer(context),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Disclaimer banner
                  _buildDisclaimerBanner(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_photos.length} locked items',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      thickness: 8.0,
                      radius: const Radius.circular(4.0),
                      thumbColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1.5),
                              child: Row(
                                children: [
                                  for (int i = 0; i < 4; i++)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 1.5),
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
              ),
            // Processing overlay
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Moving files…',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Uninstalling the app will permanently delete locked files.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Uninstalling the app will delete locked files.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
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
          final album = AlbumModel(
            id: 'locked',
            name: 'Locked Folder',
            entries: _photos.map((p) => p.asset).toList(),
          );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewerScreen(
                index: photo.index ?? 0,
                initialPhotos: List.unmodifiable(_photos),
                sourceAlbums: album,
              ),
            ),
          );
          if (mounted) _loadMedia();
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
          ],
        ),
      ),
    );
  }
}
