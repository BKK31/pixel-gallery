import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SingleViewerScreen extends StatefulWidget {
  final File file;

  const SingleViewerScreen({super.key, required this.file});

  @override
  State<SingleViewerScreen> createState() => _SingleViewerScreenState();
}

class _SingleViewerScreenState extends State<SingleViewerScreen> {
  late bool _isVideo;
  Player? _player;
  VideoController? _controller;
  bool _isPlaying = false;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _checkFileType();
  }

  void _checkFileType() {
    String path = widget.file.path.toLowerCase();
    _isVideo =
        path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');

    if (_isVideo) {
      _player = Player();
      _controller = VideoController(_player!);
      _player!.open(Media(widget.file.path));
      _player!.setPlaylistMode(PlaylistMode.loop);
      _player!.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _togglePlay() {
    if (_player == null) return;
    _player!.playOrPause();
  }

  Future<void> _showInfoBottomSheet() async {
    int? sizeBytes = await widget.file.length();
    String sizeStr = "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    DateTime lastMod = await widget.file.lastModified();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "File Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.description),
                title: Text(widget.file.path.split('/').last),
                subtitle: Text(sizeStr),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text(DateFormat.yMMMd().format(lastMod)),
                subtitle: Text(DateFormat.jm().format(lastMod)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showUI = !_showUI;
              });
            },
            child: _isVideo
                ? Center(
                    child: _controller != null
                        ? Video(
                            controller: _controller!,
                            controls: NoVideoControls,
                          )
                        : CircularProgressIndicator(),
                  )
                : PhotoView(
                    imageProvider: FileImage(widget.file),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                  ),
          ),
          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.5),
                iconTheme: IconThemeData(color: Colors.white),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (_isVideo)
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlay,
                    ),
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: _showInfoBottomSheet,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
