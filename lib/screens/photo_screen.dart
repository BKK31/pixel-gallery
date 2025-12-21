import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../services/media_service.dart';
import '../models/photo_model.dart';
import 'package:intl/intl.dart';
import '../screens/viewer_screen.dart';

class PhotoScreen extends StatefulWidget {
  final AssetPathEntity album;

  const PhotoScreen({super.key, required this.album});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  List<dynamic> _groupedItems = [];

  final MediaService _service = MediaService();
  List<PhotoModel> _photos = [];
  bool _loading = true;

  Future<void> _init() async {
    bool perm = await _service.requestPermission();
    if (!perm) {
      return;
    }
    final media = await _service.getMedia(album: widget.album, page: 0);
    setState(() {
      _photos = media;
      _groupedItems = _groupedPhotos(media);
      _loading = false;
    });
  }

  List<dynamic> _groupedPhotos(List<PhotoModel> photos) {
    String? lastDateLabel;
    List<dynamic> grouped = [];
    List<PhotoModel> currentDayPhotos = [];
    for (var photo in photos) {
      var dateLabel = DateFormat('MMMM d, yyyy').format(photo.timeTaken);
      if (dateLabel != lastDateLabel) {
        if (currentDayPhotos.isNotEmpty) {
          grouped.add(List<PhotoModel>.from(currentDayPhotos));
          currentDayPhotos.clear();
        }
        grouped.add(dateLabel);
        lastDateLabel = dateLabel;
      }
      currentDayPhotos.add(photo);
    }
    if (currentDayPhotos.isNotEmpty) {
      grouped.add(currentDayPhotos);
    }
    return grouped;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: _groupedItems.length,
        itemBuilder: (context, index) {
          final item = _groupedItems[index];

          if (item is String) {
            return Container(
              padding: EdgeInsets.all(12),
              child: Text(
                item,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          } else if (item is List<PhotoModel>) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: item.length,
              itemBuilder: (context, index) {
                final photo = item[index];
                final globalIndex = _photos.indexOf(photo);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewerScreen(
                          index: globalIndex,
                          initialPhotos: _photos,
                          sourceAlbums: widget.album,
                        ),
                      ),
                    );
                  },
                  child: AssetEntityImage(
                    photo.asset,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(200),
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
