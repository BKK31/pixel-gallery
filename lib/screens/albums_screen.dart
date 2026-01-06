import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'photo_screen.dart';
import 'package:flutter/services.dart';
import 'recycle_bin_screen.dart';
import 'favourites_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen>
    with AutomaticKeepAliveClientMixin {
  List<AssetPathEntity> _albums = [];
  bool _loading = true;
  final MediaService _service = MediaService();

  @override
  bool get wantKeepAlive => true;

  // Initializes the screen: requests permissions and fetches all albums.
  Future<void> _init() async {
    bool perm = await _service.requestPermission();
    if (!perm) {
      return;
    }
    final albums = await _service.getAlbums();
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  void _onGalleryChange(MethodCall call) {
    _service.clearCache();
    _init();
  }

  @override
  void initState() {
    super.initState();
    _init();
    PhotoManager.addChangeCallback(_onGalleryChange);
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onGalleryChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                        child: FutureBuilder<List<AssetEntity>>(
                          future: album.getAssetListRange(start: 0, end: 1),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return AssetEntityImage(
                                snapshot.data![0],
                                isOriginal: false,
                                thumbnailSize: const ThumbnailSize.square(300),
                                fit: BoxFit.cover,
                              );
                            }
                            return const Center(
                              child: Icon(Icons.photo_library_outlined),
                            );
                          },
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
                    FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            '${snapshot.data} items',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
