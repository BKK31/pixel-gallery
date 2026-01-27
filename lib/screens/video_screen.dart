import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumina_gallery/models/aves_entry.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoScreen extends StatefulWidget {
  final AvesEntry asset;
  final bool controlsVisible;
  final Player? player;
  final VideoController? controller;

  const VideoScreen({
    super.key,
    required this.asset,
    required this.controlsVisible,
    required this.player,
    required this.controller,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _isDragging = false;
  double _dragValue = 0;
  DateTime? _lastSeekTime;
  Timer? _progressTimer;
  final List<StreamSubscription> _subscriptions = [];

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    // Update seekbar every 500ms when controls are visible
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted &&
          widget.player != null &&
          widget.controlsVisible &&
          !_isDragging) {
        setState(() {});
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _initSubscriptions();
    if (widget.controlsVisible) {
      _startProgressTimer();
    }
    if (widget.player?.state.playing == true) {
      _enableWakelock();
    }
  }

  void _initSubscriptions() {
    if (widget.player != null) {
      _subscriptions.add(
        widget.player!.stream.playing.listen((playing) {
          _onVideoStateChange();
        }),
      );
    }
  }

  @override
  void didUpdateWidget(VideoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      for (var s in _subscriptions) {
        s.cancel();
      }
      _subscriptions.clear();
      _initSubscriptions();

      if (widget.player?.state.playing == true) {
        _enableWakelock();
      } else {
        _disableWakelock();
      }
    }

    if (oldWidget.controlsVisible != widget.controlsVisible) {
      if (widget.controlsVisible) {
        _startProgressTimer();
        setState(() {});
      } else {
        _stopProgressTimer();
      }
    }
  }

  void _onVideoStateChange() {
    if (!mounted) return;

    final isPlaying = widget.player?.state.playing ?? false;

    if (isPlaying) {
      _enableWakelock();
    } else {
      _disableWakelock();
      if (widget.controlsVisible) {
        setState(() {});
      }
    }
  }

  void _enableWakelock() {
    WakelockPlus.enable();
  }

  void _disableWakelock() {
    WakelockPlus.disable();
  }

  @override
  void dispose() {
    _stopProgressTimer();
    _disableWakelock();
    for (var s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.player != null && widget.controller != null) {
      final currentPosition = _isDragging
          ? Duration(milliseconds: _dragValue.toInt())
          : widget.player!.state.position;

      // Ensure duration is at least 1ms to avoid slider issues
      final duration = widget.player!.state.duration.inMilliseconds > 0
          ? widget.player!.state.duration
          : const Duration(milliseconds: 1);

      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Video(
              controller: widget.controller!,
              controls: NoVideoControls,
            ),
          ),
          if (widget.controlsVisible)
            Positioned.fill(
              child: Center(
                child: IconButton(
                  onPressed: () {
                    widget.player!.playOrPause();
                    setState(() {});
                  },
                  icon: widget.player!.state.playing
                      ? const Icon(Icons.pause_circle)
                      : const Icon(Icons.play_circle),
                  iconSize: 50,
                  color: Colors.white,
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
                                ? _dragValue.clamp(
                                    0.0,
                                    duration.inMilliseconds.toDouble(),
                                  )
                                : widget.player!.state.position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                        0.0,
                                        duration.inMilliseconds.toDouble(),
                                      ),
                            min: 0.0,
                            max: duration.inMilliseconds.toDouble(),
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
                                widget.player!.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              }
                            },
                            onChangeEnd: (value) {
                              widget.player!
                                  .seek(Duration(milliseconds: value.toInt()))
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
                          _formatDuration(widget.player!.state.duration),
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
                          icon: widget.player!.state.volume == 0
                              ? const Icon(Icons.volume_off)
                              : const Icon(Icons.volume_up),
                          color: Colors.white,
                          iconSize: 28,
                          onPressed: () {
                            setState(() {
                              widget.player!.setVolume(
                                widget.player!.state.volume == 0 ? 100 : 0,
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
