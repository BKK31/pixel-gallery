import 'package:flutter/material.dart';
import 'dart:async';
import '../services/media_service.dart';
import '../services/trash_service.dart';
import '../services/settings_service.dart';
import '../models/album_model.dart';
import '../widgets/aves_entry_image.dart';
import 'photo_screen.dart';
import 'recycle_bin_screen.dart';
import 'favourites_screen.dart';
import 'package:lumina_gallery/l10n/app_localizations.dart';

class AlbumsScreen extends StatefulWidget {
  final void Function(bool selecting, int count)? onSelectionChanged;

  const AlbumsScreen({super.key, this.onSelectionChanged});

  @override
  State<AlbumsScreen> createState() => AlbumsScreenState();
}

class AlbumsScreenState extends State<AlbumsScreen> {
  List<AlbumModel> _albums = [];
  bool _loading = true;
  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();
  StreamSubscription? _albumSubscription;
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedAlbumIds = {};

  Future<void> _init({bool silent = false}) async {
    if (_albums.isNotEmpty) {
      silent = true;
    }

    if (!silent) {
      if (mounted && _albums.isEmpty) {
        setState(() {
          _loading = true;
        });
      }
    }

    _service.requestPermission().then((perm) async {
      if (!perm) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      final albums = await _service.getAlbums();

      if (mounted) {
        setState(() {
          _albums = albums;
          _loading = false;
        });
      }
    });

    if (_albumSubscription == null) {
      _albumSubscription = _service.albumUpdateStream.listen((_) {
        _onAlbumUpdated();
      });
    }
  }

  void _onAlbumUpdated() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _init(silent: true);
      }
    });
  }

  // --- Selection logic ---

  void _toggleSelection(String albumId) {
    setState(() {
      if (_selectedAlbumIds.contains(albumId)) {
        _selectedAlbumIds.remove(albumId);
        if (_selectedAlbumIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedAlbumIds.add(albumId);
      }
    });
    widget.onSelectionChanged?.call(_isSelecting, _selectedAlbumIds.length);
  }

  void _startSelection(String albumId) {
    setState(() {
      _isSelecting = true;
      _selectedAlbumIds.add(albumId);
    });
    widget.onSelectionChanged?.call(true, _selectedAlbumIds.length);
  }

  void clearSelections() {
    setState(() {
      _isSelecting = false;
      _selectedAlbumIds.clear();
    });
    widget.onSelectionChanged?.call(false, 0);
  }

  /// Bulk hide/unhide the selected albums from Recents.
  Future<void> hideSelected() async {
    final hiddenAlbums = SettingsService().hiddenAlbums;
    // Determine: if ALL selected are already hidden, we unhide; else hide.
    final allHidden = _selectedAlbumIds.every(
      (id) => hiddenAlbums.contains(id),
    );

    int count = 0;
    for (final id in _selectedAlbumIds) {
      if (allHidden) {
        hiddenAlbums.remove(id);
      } else {
        hiddenAlbums.add(id);
      }
      count++;
    }
    await SettingsService().setHiddenAlbums(hiddenAlbums);
    MediaService().rebuildAlbums();
    clearSelections();
    _init(silent: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allHidden
                ? AppLocalizations.of(context)!.albumsUnhiddenCount(count)
                : AppLocalizations.of(context)!.albumsHiddenCount(count),
          ),
        ),
      );
    }
  }

  /// Bulk delete all photos inside the selected albums.
  Future<void> deleteSelected() async {
    // Gather all entries across selected albums
    final selectedAlbums =
        _albums.where((a) => _selectedAlbumIds.contains(a.id)).toList();
    final totalPhotos =
        selectedAlbums.fold<int>(0, (sum, a) => sum + a.entries.length);

    if (totalPhotos == 0) {
      clearSelections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.albumsEmptySelection)),
        );
      }
      return;
    }

    bool moveToTrash = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.albumsDeleteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.albumsDeleteContent(totalPhotos, selectedAlbums.length),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.albumsDeleteWarning,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: moveToTrash,
                onChanged: (v) => setStateDialog(() => moveToTrash = v),
                title: Text(AppLocalizations.of(context)!.albumsMoveToBin),
                subtitle: Text(
                  moveToTrash
                      ? AppLocalizations.of(context)!.albumsBinDesc
                      : AppLocalizations.of(context)!.albumsPermDeleteDesc,
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
                moveToTrash ? AppLocalizations.of(context)!.albumsMoveToBin : AppLocalizations.of(context)!.deletePermanently,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    for (final album in selectedAlbums) {
      for (final entry in album.entries) {
        if (moveToTrash) {
          await _trashService.moveToTrash(entry);
        } else {
          await _service.permanentlyDelete(entry);
        }
      }
    }

    clearSelections();
    _init(silent: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            moveToTrash
                ? AppLocalizations.of(context)!.albumsMovedToBin(totalPhotos)
                : AppLocalizations.of(context)!.albumsPermDeletedCount(totalPhotos),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _albumSubscription?.cancel();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelecting) clearSelections();
      },
      child: RawScrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        thickness: 8.0,
        radius: const Radius.circular(4.0),
        thumbColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Buttons: Favourites and Bin
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderButton(
                            context,
                            icon: Icons.star_outline,
                            label: AppLocalizations.of(context)!.albumsFavourites,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FavouritesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildHeaderButton(
                            context,
                            icon: Icons.delete_outline,
                            label: AppLocalizations.of(context)!.albumsBin,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RecycleBinScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Albums Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.88,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final album = _albums[index];
                  final isSelected = _selectedAlbumIds.contains(album.id);
                  return _buildAlbumGridItem(album, isSelected);
                }, childCount: _albums.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumGridItem(AlbumModel album, bool isSelected) {
    return GestureDetector(
      onLongPress: () {
        if (!_isSelecting) {
          _startSelection(album.id);
        }
      },
      onTap: () {
        if (_isSelecting) {
          _toggleSelection(album.id);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoScreen(album: album),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  album.entries.isNotEmpty
                      ? AvesEntryImage(
                          entry: album.entries.first,
                          extent: 300,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(Icons.photo_library_outlined),
                        ),
                  if (isSelected)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            AppLocalizations.of(context)!.albumsItemsCount(album.assetCount),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
