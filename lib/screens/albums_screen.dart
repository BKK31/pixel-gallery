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
  Timer? _debounceTimer;

  // Initializes the screen: requests permissions and fetches all albums.
  Future<void> _init({bool silent = false}) async {
    // Show cached data immediately if available
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
    // Debounce updates to avoid rapid re-fetches during sync
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _init(silent: true);
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
    _albumSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _albums.isEmpty) {
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.88,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final album = _albums[index];
              return _AlbumGridItem(album: album);
            }, childCount: _albums.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
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

class _AlbumGridItem extends StatelessWidget {
  final AlbumModel album;

  const _AlbumGridItem({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PhotoScreen(album: album)),
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
                  : const Center(child: Icon(Icons.photo_library_outlined)),
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
            '${album.assetCount} items',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
