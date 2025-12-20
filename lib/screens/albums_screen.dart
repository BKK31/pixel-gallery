import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'photo_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List<AssetPathEntity> _albums = [];
  bool _loading = true;
  final MediaService _service = MediaService();

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoScreen(album: _albums[index]),
              ),
            );
          },
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: EdgeInsets.all(2),
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FutureBuilder<List<AssetEntity>>(
                    future: _albums[index].getAssetListRange(start: 0, end: 1),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final asset = snapshot.data![0];

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AssetEntityImage(
                            asset,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize.square(300),
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _albums[index].name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
