import 'package:flutter/material.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../services/trash_service.dart';
import 'package:photo_manager/photo_manager.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<String> _trashedIds = [];
  List<AssetEntity> _trashedAssets = [];
  final TrashService _trashService = TrashService();

  // Selection
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  Future<void> _init() async {
    // Initialize the trash service and fetch the current list of trashed IDs
    await _trashService.init();
    setState(() {
      _trashedIds = _trashService.trashedIds;
    });

    List<AssetEntity?> assets = [];
    // Convert trashed IDs back to AssetEntity objects
    for (var id in _trashedIds) {
      final asset = await AssetEntity.fromId(id);
      assets.add(asset);
    }
    // Update the UI with the validity filtering of trashed assets
    setState(() {
      _trashedAssets = assets.whereType<AssetEntity>().toList();
    });
  }

  Future<void> _restore(AssetEntity asset) async {
    // Restore a single asset from trash
    await _trashService.restore(asset.id);
    _init(); // Refresh list to reflect changes
  }

  Future<void> _deletePermanently(AssetEntity asset) async {
    await _trashService.deletePermanently(asset.id);
    _init(); // Refresh list
  }

  // Multi-Selection Actions
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        // Deselect if already selected; if none selected, exit selection mode
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        // Add to selection
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _restoreSelected() async {
    // Restore all currently selected items
    for (var id in _selectedIds) {
      await _trashService.restore(id);
    }
    // Clear selection and refresh the list
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    _init();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Restored selected items")));
    }
  }

  Future<void> _deletePermanentlySelected() async {
    // Permanently delete all currently selected items
    for (var id in _selectedIds) {
      await _trashService.deletePermanently(id);
    }
    // Clear selection and refresh the list
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
    _init();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permanently deleted selected items")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelecting
            ? Text("${_selectedIds.length} Selected")
            : Text("Recycle Bin"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isSelecting
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelecting = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: _isSelecting
            ? [
                IconButton(
                  onPressed: _restoreSelected,
                  icon: Icon(Icons.restore),
                ),
                IconButton(
                  onPressed: _deletePermanentlySelected,
                  icon: Icon(Icons.delete_forever),
                ),
              ]
            : [],
      ),
      body: _trashedAssets.isEmpty
          ? Center(child: Text("Recycle Bin is empty"))
          : GridView.builder(
              itemCount: _trashedAssets.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                final asset = _trashedAssets[index];
                final isSelected = _selectedIds.contains(asset.id);

                return GestureDetector(
                  onLongPress: () {
                    if (!_isSelecting) {
                      setState(() {
                        _isSelecting = true;
                      });
                      _toggleSelection(asset.id);
                    }
                  },
                  onTap: () {
                    if (_isSelecting) {
                      _toggleSelection(asset.id);
                    } else {
                      // Show Dialog to Restore or Delete
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Actions"),
                          content: Text(
                            "Do you want to restore or permanently delete this item?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                _restore(asset);
                                Navigator.pop(context);
                              },
                              child: Text("Restore"),
                            ),
                            TextButton(
                              onPressed: () {
                                _deletePermanently(asset);
                                Navigator.pop(context);
                              },
                              child: Text(
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
                      AssetEntityImage(
                        asset,
                        isOriginal: false,
                        thumbnailSize: ThumbnailSize.square(200),
                        fit: BoxFit.cover,
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
    );
  }
}
