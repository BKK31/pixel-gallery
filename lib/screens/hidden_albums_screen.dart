import 'package:flutter/material.dart';
import 'dart:async';
import '../services/media_service.dart';
import '../services/trash_service.dart';
import '../services/settings_service.dart';
import '../models/album_model.dart';
import '../widgets/aves_entry_image.dart';
import '../l10n/app_localizations.dart';
import 'photo_screen.dart';

class HiddenAlbumsScreen extends StatefulWidget {
  const HiddenAlbumsScreen({super.key});

  @override
  State<HiddenAlbumsScreen> createState() => _HiddenAlbumsScreenState();
}

class _HiddenAlbumsScreenState extends State<HiddenAlbumsScreen> {
  List<AlbumModel> _hiddenAlbums = [];
  bool _loading = true;
  final MediaService _service = MediaService();
  final TrashService _trashService = TrashService();

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedAlbumIds = {};

  @override
  void initState() {
    super.initState();
    _loadHiddenAlbums();
  }

  Future<void> _loadHiddenAlbums() async {
    final hiddenIds = SettingsService().hiddenAlbums;
    if (hiddenIds.isEmpty) {
      setState(() {
        _hiddenAlbums = [];
        _loading = false;
      });
      return;
    }

    final allAlbums = await _service.getPhotos();
    final hidden = allAlbums
        .where((a) => !a.isAll && hiddenIds.contains(a.id))
        .toList();

    if (mounted) {
      setState(() {
        _hiddenAlbums = hidden;
        _loading = false;
      });
    }
  }

  // --- Selection logic ---

  void _toggleSelection(String albumId) {
    setState(() {
      if (_selectedAlbumIds.contains(albumId)) {
        _selectedAlbumIds.remove(albumId);
        if (_selectedAlbumIds.isEmpty) _isSelecting = false;
      } else {
        _selectedAlbumIds.add(albumId);
      }
    });
  }

  void _startSelection(String albumId) {
    setState(() {
      _isSelecting = true;
      _selectedAlbumIds.add(albumId);
    });
  }

  void _clearSelections() {
    setState(() {
      _isSelecting = false;
      _selectedAlbumIds.clear();
    });
  }

  /// Bulk unhide all selected albums.
  Future<void> _unhideSelected() async {
    final hiddenAlbums = SettingsService().hiddenAlbums;
    int count = 0;
    for (final id in _selectedAlbumIds) {
      if (hiddenAlbums.remove(id)) count++;
    }
    await SettingsService().setHiddenAlbums(hiddenAlbums);
    MediaService().rebuildAlbums();
    _clearSelections();
    _loadHiddenAlbums();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.albumsUnhiddenCount(count))),
      );
    }
  }

  /// Bulk delete all photos inside the selected hidden albums.
  Future<void> _deleteSelected() async {
    final selectedAlbums =
        _hiddenAlbums.where((a) => _selectedAlbumIds.contains(a.id)).toList();
    final totalPhotos =
        selectedAlbums.fold<int>(0, (sum, a) => sum + a.entries.length);

    if (totalPhotos == 0) {
      _clearSelections();
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

    for (final album in selectedAlbums) {
      for (final entry in album.entries) {
        if (moveToTrash) {
          await _trashService.moveToTrash(entry);
        } else {
          await _service.permanentlyDelete(entry);
        }
      }
    }

    _clearSelections();
    _loadHiddenAlbums();

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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelecting) _clearSelections();
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSelecting
              ? Text(AppLocalizations.of(context)!.homeSelectedCount(_selectedAlbumIds.length))
              : Text(AppLocalizations.of(context)!.homeHiddenAlbums),
          leading: _isSelecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelections,
                )
              : null,
          actions: _isSelecting
              ? [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    tooltip: AppLocalizations.of(context)!.unhideSelected,
                    onPressed: _unhideSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: AppLocalizations.of(context)!.deleteContents,
                    onPressed: _deleteSelected,
                  ),
                ]
              : [],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _hiddenAlbums.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noHiddenAlbums,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.hiddenAlbumsDesc,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _hiddenAlbums.length,
                    itemBuilder: (context, index) {
                      final album = _hiddenAlbums[index];
                      final isSelected =
                          _selectedAlbumIds.contains(album.id);
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                album.entries.isNotEmpty
                                    ? AvesEntryImage(
                                        entry: album.entries.first,
                                        extent: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                        child: const Icon(
                                          Icons.photo_library_outlined,
                                        ),
                                      ),
                                if (isSelected)
                                  Container(
                                    color: Colors.black.withOpacity(0.4),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        title: Text(album.name),
                        subtitle: Text(AppLocalizations.of(context)!.albumsItemsCount(album.assetCount)),
                        selected: isSelected,
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
                                builder: (_) => PhotoScreen(album: album),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
