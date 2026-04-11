import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../services/media_service.dart';
import '../services/album_operation_service.dart';
import '../widgets/aves_entry_image.dart';
import '../l10n/app_localizations.dart';

class AddToAlbumSheet extends StatefulWidget {
  final List<PhotoModel> selectedPhotos;

  const AddToAlbumSheet({super.key, required this.selectedPhotos});

  static Future<void> show(BuildContext context, List<PhotoModel> photos) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddToAlbumSheet(selectedPhotos: photos),
    );
  }

  @override
  State<AddToAlbumSheet> createState() => _AddToAlbumSheetState();
}

class _AddToAlbumSheetState extends State<AddToAlbumSheet> {
  final MediaService _mediaService = MediaService();
  final AlbumOperationService _albumOperationService = AlbumOperationService();
  
  List<AlbumModel> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albums = await _mediaService.getAlbums();
    if (mounted) {
      setState(() {
        _albums = albums;
        _loading = false;
      });
    }
  }

  Future<void> _handleAlbumSelection(String? albumName, Directory? destination) async {
    if (destination == null && albumName != null) {
      // Must create new folder
      destination = await _albumOperationService.createAlbumDirectory(albumName);
      if (destination == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorCreateAlbum)));
        }
        return;
      }
    }

    if (destination == null) return;

    // Ask for Move vs Copy
    if (!mounted) return;
    final String? action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(albumName != null ? AppLocalizations.of(context)!.addToSpecificAlbum(albumName) : AppLocalizations.of(context)!.addToAlbum),
        content: Text(AppLocalizations.of(context)!.moveOrCopyDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'copy'),
            child: Text(AppLocalizations.of(context)!.copy),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'move'),
            child: Text(AppLocalizations.of(context)!.move, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

    if (action == null) return;

    if (mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(action == 'move' ? AppLocalizations.of(context)!.movingItems : AppLocalizations.of(context)!.copyingItems),
            ],
          ),
        ),
      );
    }

    final entries = widget.selectedPhotos.map((p) => p.asset).toList();
    int count = 0;
    if (action == 'move') {
      count = await _albumOperationService.movePhotos(entries, destination);
    } else {
      count = await _albumOperationService.copyPhotos(entries, destination);
    }

    if (mounted) {
      Navigator.pop(context); // close progress dialog
      Navigator.pop(context); // close AddToAlbumSheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'move' ? AppLocalizations.of(context)!.moveSuccessCount(count) : AppLocalizations.of(context)!.copySuccessCount(count))),
      );
    }
  }

  Future<void> _createNewAlbum() async {
    final TextEditingController nameController = TextEditingController();
    final String? albumName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createNewAlbum),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.albumName,
            hintText: AppLocalizations.of(context)!.albumNameHint,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
            }, 
            child: Text(AppLocalizations.of(context)!.create)
          ),
        ],
      )
    );

    if (albumName != null) {
      await _handleAlbumSelection(albumName, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                AppLocalizations.of(context)!.addToAlbum,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add, 
                  color: Theme.of(context).colorScheme.onPrimaryContainer
                ),
              ),
              title: Text(AppLocalizations.of(context)!.createNewAlbum, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: _createNewAlbum,
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  // If it's a special album like "Recent", maybe skip or handle differently
                  if (album.isAll) return const SizedBox.shrink();

                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: album.entries.isNotEmpty
                        ? AvesEntryImage(entry: album.entries.first, extent: 100, fit: BoxFit.cover)
                        : const Icon(Icons.photo_library),
                    ),
                    title: Text(album.name),
                    subtitle: Text(AppLocalizations.of(context)!.albumsItemsCount(album.assetCount)),
                    onTap: () async {
                      if (album.id == null || album.id.isEmpty) return;
                      await _handleAlbumSelection(album.name, Directory(album.id));
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
