import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/recents_screen.dart';
import 'package:lumina_gallery/screens/settings_screen.dart';

enum MenuItems { settings, recycleBin }

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeRefresh;

  const HomeScreen({super.key, this.onThemeRefresh});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late Future<void> _initSettings;

  final List _pages = [RecentsScreen(), AlbumsScreen()];

  @override
  void initState() {
    super.initState();
    _initSettings = _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    final bool startAlbum = await SettingsScreen.getStartupAtAlbums();
    setState(() {
      _selectedIndex = startAlbum ? 1 : 0;
    });
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ).then((_) {
      widget.onThemeRefresh?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initSettings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Lumina Gallery"),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              PopupMenuButton<MenuItems>(
                onSelected: (MenuItems item) {
                  if (item == MenuItems.settings) {
                    _openSettings();
                  }

                  if (item == MenuItems.recycleBin) {
                    // later: navigate to recycle bin
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<MenuItems>(
                    value: MenuItems.settings,
                    child: Text('Settings'),
                  ),
                  PopupMenuItem<MenuItems>(
                    value: MenuItems.recycleBin,
                    child: Text('Recycle Bin'),
                  ),
                ],
              ),
            ],
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _navigateBottomBar,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.photo), label: "Photos"),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_album),
                label: "Albums",
              ),
            ],
          ),
        );
      },
    );
  }
}
