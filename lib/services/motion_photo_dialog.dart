import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:motion_photos/motion_photos.dart';
import 'package:path_provider/path_provider.dart';

// A dialog widget that plays the video portion of a Motion Photo.
// It uses the MotionPhotos package to extract the video file from the image
// and plays it using VideoPlayerController.
class MotionPhotoDialog extends StatefulWidget {
  final File motionPhotoFile;
  final double aspectRatio;

  const MotionPhotoDialog({
    super.key,
    required this.motionPhotoFile,
    required this.aspectRatio,
  });

  @override
  State<MotionPhotoDialog> createState() => _MotionPhotoDialogState();
}

class _MotionPhotoDialogState extends State<MotionPhotoDialog> {
  Player? _player;
  VideoController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final motionPhotos = MotionPhotos(widget.motionPhotoFile.path);
      final videoFile = await motionPhotos.getMotionVideoFile(
        await getTemporaryDirectory(),
      );

      _player = Player();
      _controller = VideoController(_player!);
      await _player!.open(Media(videoFile.path));
      await _player!.setPlaylistMode(PlaylistMode.loop);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing motion video: $e");
      if (mounted) {
        setState(() {
          _error = "Failed to load motion video";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main video content
          Center(
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: _buildContent(),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(_error!, style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Use FittedBox with BoxFit.cover to crop properly
    return Container(
      color: Colors.black,
      child: Video(
        controller: _controller!,
        fit: BoxFit.cover,
        controls: NoVideoControls,
      ),
    );
  }
}
