import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  VideoPlayerController? _controller;
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

      _controller = VideoPlayerController.file(videoFile);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

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
    _controller?.dispose();
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

    if (_controller?.value.isInitialized ?? false) {
      // Use FittedBox with BoxFit.cover to crop properly
      return Container(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}
