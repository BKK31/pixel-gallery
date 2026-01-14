import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:lumina_gallery/widgets/aves_entry_image_provider.dart';

class AvesEntryImage extends StatelessWidget {
  final AvesEntry entry;
  final double extent;
  final BoxFit fit;

  const AvesEntryImage({
    super.key,
    required this.entry,
    this.extent = 200,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image(
        image: AvesEntryImageProvider(entry, extent: extent),
        width: extent,
        height: extent,
        fit: fit,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return Container(color: Colors.grey[300]);
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          );
        },
      ),
    );
  }
}
