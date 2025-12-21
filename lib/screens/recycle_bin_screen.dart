import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<String> _debugLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _findTrashAlbums();
  }

  Future<void> _findTrashAlbums() async {
    // 1. Ask for everything, including hidden stuff
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(containsPathModified: true),
    );

    // 2. Put the names in a list to show on screen
    List<String> logs = [];
    for (var path in paths) {
      // We are looking for "Trash", "Bin", or has isAll=false and huge count
      logs.add("${path.name} (ID: ${path.id}, Count: ${path.assetCount})");
    }

    setState(() {
      _debugLogs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recycle Bin Debugger")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _debugLogs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_debugLogs[index]),
                  leading: Icon(Icons.folder),
                );
              },
            ),
    );
  }
}
