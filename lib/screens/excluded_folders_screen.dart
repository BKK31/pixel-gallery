import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../services/settings_service.dart';
import '../services/media_service.dart';
import '../models/filters.dart';

class ExcludedFoldersScreen extends StatefulWidget {
  const ExcludedFoldersScreen({super.key});

  @override
  State<ExcludedFoldersScreen> createState() => _ExcludedFoldersScreenState();
}

class _ExcludedFoldersScreenState extends State<ExcludedFoldersScreen> {
  late Set<GalleryFilter> _hiddenFilters;

  @override
  void initState() {
    super.initState();
    _hiddenFilters = SettingsService().hiddenFilters;
  }

  Future<void> _addFolder() async {
    final TextEditingController controller = TextEditingController();

    final String? selectedDirectory = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Excluded Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g., /storage/emulated/0/Movies',
              labelText: 'Absolute Path',
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Exclude'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (selectedDirectory != null) {
      if (!selectedDirectory.startsWith('/')) {
        return; // Basic validation
      }
      setState(() {
        _hiddenFilters.add(PathFilter(selectedDirectory));
      });
      await SettingsService().setHiddenFilters(_hiddenFilters);
      MediaService().clearCache();
      MediaService().rebuildAlbums();
    }
  }

  Future<void> _removeFilter(GalleryFilter filter) async {
    setState(() {
      _hiddenFilters.remove(filter);
    });
    await SettingsService().setHiddenFilters(_hiddenFilters);
    MediaService().clearCache();
    MediaService().rebuildAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarM3E(
        title: const Text("Excluded Folders"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _hiddenFilters.isEmpty
          ? Center(
              child: Text(
                "No filters active.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _hiddenFilters.length,
              itemBuilder: (context, index) {
                final filter = _hiddenFilters.elementAt(index);
                if (filter is PathFilter) {
                  return ListTile(
                    leading: const Icon(Icons.folder_off),
                    title: Text(filter.path.split('/').last),
                    subtitle: Text(filter.path),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeFilter(filter),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFolder,
        icon: const Icon(Icons.add),
        label: const Text("Add Folder"),
      ),
    );
  }
}
