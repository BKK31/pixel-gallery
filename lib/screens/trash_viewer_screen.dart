import 'dart:io';
import 'package:flutter/material.dart';
import '../services/trash_service.dart';

/// A full-screen viewer for a single trashed image with Restore and Delete
/// buttons in the bottom overlay.
class TrashViewerScreen extends StatefulWidget {
  final List<File> files;
  final int initialIndex;

  const TrashViewerScreen({
    super.key,
    required this.files,
    required this.initialIndex,
  });

  @override
  State<TrashViewerScreen> createState() => _TrashViewerScreenState();
}

class _TrashViewerScreenState extends State<TrashViewerScreen> {
  final TrashService _trashService = TrashService();
  late PageController _controller;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final file = widget.files[_currentIndex];
    final success = await _trashService.restore(file.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Restored successfully' : 'Failed to restore'),
      ),
    );
    if (success) Navigator.pop(context, 'restored');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _trashService.deletePermanently(widget.files[_currentIndex].path);
    if (!mounted) return;
    Navigator.pop(context, 'deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo gallery
          GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.files.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final file = widget.files[index];
                return InteractiveViewer(
                  child: Center(
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top AppBar
          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.5),
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  '${_currentIndex + 1} / ${widget.files.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

          // Bottom overlay with Restore / Delete
          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.only(
                  top: 8,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _restore,
                      icon: const Icon(Icons.restore, color: Colors.white),
                      label: const Text(
                        'Restore',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
