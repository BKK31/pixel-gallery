import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  final AvesEntry asset;
  final bool controlsVisible;
  final VideoPlayerController? videoController;

  const VideoScreen({
    super.key,
    required this.asset,
    required this.controlsVisible,
    required this.videoController,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _isDragging = false;
  double _dragValue = 0;
  DateTime? _lastSeekTime;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    widget.videoController?.addListener(() {
      if (mounted && !_isDragging) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoController != null &&
        widget.videoController!.value.isInitialized) {
      final currentPosition = _isDragging
          ? Duration(seconds: _dragValue.toInt())
          : widget.videoController!.value.position;

      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.videoController!.value.aspectRatio,
              child: Stack(
                children: [
                  VideoPlayer(widget.videoController!),
                  if (widget.controlsVisible)
                    Positioned.fill(
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              widget.videoController!.value.isPlaying
                                  ? widget.videoController!.pause()
                                  : widget.videoController!.play();
                            });
                          },
                          icon: widget.videoController!.value.isPlaying
                              ? const Icon(Icons.pause_circle)
                              : const Icon(Icons.play_circle),
                          iconSize: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.controlsVisible)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDuration(currentPosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _isDragging
                                ? _dragValue
                                : widget
                                      .videoController!
                                      .value
                                      .position
                                      .inSeconds
                                      .toDouble(),
                            min: 0.0,
                            max: widget
                                .videoController!
                                .value
                                .duration
                                .inSeconds
                                .toDouble(),
                            onChangeStart: (value) {
                              setState(() {
                                _isDragging = true;
                                _dragValue = value;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _dragValue = value;
                              });
                              final now = DateTime.now();
                              if (_lastSeekTime == null ||
                                  now.difference(_lastSeekTime!) >
                                      const Duration(milliseconds: 50)) {
                                _lastSeekTime = now;
                                widget.videoController!.seekTo(
                                  Duration(seconds: value.toInt()),
                                );
                              }
                            },
                            onChangeEnd: (value) {
                              widget.videoController!
                                  .seekTo(Duration(seconds: value.toInt()))
                                  .then((_) {
                                    setState(() {
                                      _isDragging = false;
                                    });
                                  });
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        Text(
                          _formatDuration(
                            widget.videoController!.value.duration,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: widget.videoController!.value.volume == 0
                              ? const Icon(Icons.volume_off)
                              : const Icon(Icons.volume_up),
                          color: Colors.white,
                          iconSize: 28,
                          onPressed: () {
                            setState(() {
                              widget.videoController!.setVolume(
                                widget.videoController!.value.volume == 0
                                    ? 1
                                    : 0,
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
      return const Center(child: CircularProgressIndicator());
    }
  }
}
