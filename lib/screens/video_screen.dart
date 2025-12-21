import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  final AssetEntity? asset;
  final File? file;
  final bool controlsVisible;

  const VideoScreen({
    super.key,
    this.asset,
    this.file,
    required this.controlsVisible,
  }) : assert(
         asset != null || file != null,
         "Either asset or file must be provided",
       );

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _controller;

  Future<void> _initVideo() async {
    File? videoFile;
    if (widget.asset != null) {
      videoFile = await widget.asset!.file;
    } else {
      videoFile = widget.file;
    }

    if (videoFile == null) return;

    _controller =
        VideoPlayerController.file(
            videoFile,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..initialize().then((_) {
            setState(() {});
            _controller!.setLooping(true);
            _controller!.play();
            // Add listener to update seekbar
            _controller!.addListener(() {
              if (mounted) setState(() {});
            });
          });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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
      return Stack(
        fit: StackFit.expand,
        children: [
          // Video player centered
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                children: [
                  VideoPlayer(_controller!),
                  // Play/Pause button in center of video
                  if (widget.controlsVisible)
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Seekbar and controls at bottom of screen
          if (widget.controlsVisible)
            Positioned(
              bottom: 80, // Above your bottom overlay
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seekbar
                    Row(
                      children: [
                        Text(
                          _formatDuration(_controller!.value.position),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Expanded(
                          child: Slider(
                            value: _controller!.value.position.inSeconds
                                .toDouble(),
                            min: 0.0,
                            max: _controller!.value.duration.inSeconds
                                .toDouble(),
                            onChanged: (value) {
                              _controller!.seekTo(
                                Duration(seconds: value.toInt()),
                              );
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        Text(
                          _formatDuration(_controller!.value.duration),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    // Volume button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: _controller!.value.volume == 0
                              ? Icon(Icons.volume_off)
                              : Icon(Icons.volume_up),
                          color: Colors.white,
                          iconSize: 28,
                          onPressed: () {
                            setState(() {
                              _controller!.setVolume(
                                _controller!.value.volume == 0 ? 1 : 0,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }
}
