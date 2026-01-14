import 'package:flutter/material.dart';
import 'dart:async';
import '../services/media_service.dart';
import '../models/album_model.dart';
import '../widgets/aves_entry_image.dart';
import 'photo_screen.dart';
import 'recycle_bin_screen.dart';
import 'favourites_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List<AlbumModel> _albums = [];
  bool _loading = true;
  final MediaService _service = MediaService();
  StreamSubscription? _albumSubscription;

  // Initializes the screen: requests permissions and fetches all albums.
  Future<void> _init() async {
    bool perm = await _service.requestPermission();
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

    _albumSubscription?.cancel();
    _albumSubscription = _service.albumUpdateStream.listen((_) {
      _init();
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _albumSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
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
                        label: 'Favourites',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavouritesScreen(),
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
                        label: 'Bin',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecycleBinScreen(),
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
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final album = _albums[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoScreen(album: album),
                    ),
                  );
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
                        child: album.entries.isNotEmpty
                            ? AvesEntryImage(
                                entry: album.entries.first,
                                extent: 300,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(Icons.photo_library_outlined),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      album.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${album.assetCount} items',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: _albums.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
