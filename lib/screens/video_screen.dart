import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  final AssetEntity videoFile;
  final bool controlsVisible;
  const VideoScreen({
    super.key,
    required this.videoFile,
    required this.controlsVisible,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _controller;

  Future<void> _initVideo() async {
    final file = await widget.videoFile.file;

    if (file == null) return;

    _controller =
        VideoPlayerController.file(
            file,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..initialize().then((_) {
            setState(() {});
            _controller!.setLooping(true);
            _controller!.play();
          });
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _controller!.value.isInitialized) {
      return Center(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            if (widget.controlsVisible) ...[
              Positioned.fill(
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      });
                    },
                    icon: _controller!.value.isPlaying
                        ? Icon(Icons.pause_circle)
                        : Icon(Icons.play_circle),
                    iconSize: 50,
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                right: 10,
                child: IconButton(
                  icon: _controller!.value.volume == 0
                      ? Icon(Icons.volume_off)
                      : Icon(Icons.volume_up),
                  onPressed: () {
                    setState(() {
                      _controller!.setVolume(
                        _controller!.value.volume == 0 ? 1 : 0,
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }
}
