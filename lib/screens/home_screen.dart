import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/recents_screen.dart';
import 'package:lumina_gallery/screens/recycle_bin_screen.dart';
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

  // Load startup preferences (which screen to show first: Photos or Albums)
  // This is determined by the 'startup_at_albums' setting.
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

  // Opens the Settings screen and passes the theme refresh callback
  // so that if the user changes the theme (e.g. Material You), the app updates immediately.
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SettingsScreen(onThemeChange: widget.onThemeRefresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initSettings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while settings are being loaded
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Pixel Gallery"),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              PopupMenuButton<MenuItems>(
                onSelected: (MenuItems item) {
                  if (item == MenuItems.settings) {
                    _openSettings();
                  }

                  if (item == MenuItems.recycleBin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecycleBinScreen(),
                      ),
                    );
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
