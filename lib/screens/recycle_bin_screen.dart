import 'dart:io';
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../services/trash_service.dart';
import 'package:photo_manager/photo_manager.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<String> _trashedPaths = [];
  List<File> _trashedFiles = [];
  final TrashService _trashService = TrashService();

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedPaths = {};

  // Initializes the screen: requests permissions (implied) and fetches trashed files.
  Future<void> _init() async {
    // Initialize the trash service and fetch the current list of trashed IDs
    await _trashService.init();
    setState(() {
      _trashedPaths = _trashService.trashedPaths;

      _trashedFiles = _trashedPaths
          .map((path) => File(path))
          .where((file) => file.existsSync())
          .toList();
    });
  }

  // Restores a single file using the service and refreshes the list.
  Future<void> _restore(File file) async {
    // Restore a single asset from trash
    final success = await _trashService.restore(file.path);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Restored successfully")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to restore item. Check permissions.")),
        );
      }
    }
    _init(); // Refresh list to reflect changes
  }

  Future<void> _deletePermanently(File file) async {
    await _trashService.deletePermanently(file.path);
    _init(); // Refresh list
  }

  // Multi-Selection Actions
  // Toggles selection state for a file path.
  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        // Deselect if already selected; if none selected, exit selection mode
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) {
          _isSelecting = false;
        }
      } else {
        // Add to selection
        _selectedPaths.add(path);
      }
    });
  }

  // Restores all selected items to the gallery.
  Future<void> _restoreSelected() async {
    // Restore all currently selected items
    int successCount = 0;
    int failCount = 0;
    for (var path in _selectedPaths) {
      bool result = await _trashService.restore(path);
      if (result)
        successCount++;
      else
        failCount++;
    }
    _clearSelection();
    _init();
    if (mounted) {
      String msg = "Restored $successCount items";
      if (failCount > 0) msg += ", failed $failCount";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _deletePermanentlySelected() async {
    // Permanently delete all currently selected items
    for (var path in _selectedPaths) {
      await _trashService.deletePermanently(path);
    }
    _clearSelection();
    _init();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permanently deleted selected items")),
      );
    }
  }

  void _clearSelection() {
    setState(() {
      _isSelecting = false;
      _selectedPaths.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelecting) {
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: AppBarM3E(
          title: _isSelecting
              ? Text(
                  "${_selectedPaths.length} Selected",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  "Recycle Bin",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          centerTitle: false,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: _isSelecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
          actions: _isSelecting
              ? [
                  IconButton(
                    onPressed: _restoreSelected,
                    icon: const Icon(Icons.restore),
                  ),
                  IconButton(
                    onPressed: _deletePermanentlySelected,
                    icon: const Icon(Icons.delete_forever),
                  ),
                ]
              : [],
        ),
        body: _trashedFiles.isEmpty
            ? const Center(child: Text("Recycle Bin is empty"))
            : Padding(
                padding: const EdgeInsets.all(5),
                child: GridView.builder(
                  itemCount: _trashedFiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Increased size slightly
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemBuilder: (context, index) {
                    final file = _trashedFiles[index];
                    final isSelected = _selectedPaths.contains(file.path);
                    return GestureDetector(
                      onLongPress: () {
                        if (!_isSelecting) {
                          setState(() => _isSelecting = true);
                          _toggleSelection(file.path);
                        }
                      },
                      onTap: () {
                        if (_isSelecting) {
                          _toggleSelection(file.path);
                        } else {
                          // Show Dialog
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Actions"),
                              content: const Text("Restore or Delete?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    _restore(file);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Restore"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deletePermanently(file);
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          if (isSelected)
                            Container(
                              color: Colors.black.withOpacity(0.4),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
