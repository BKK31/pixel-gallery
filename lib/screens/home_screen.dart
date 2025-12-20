import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/recents_screen.dart';
import 'package:lumina_gallery/screens/settings_screen.dart';

enum MenuItems { settings, recycleBin }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  MenuItems? selectedItem;

  final List _pages = [RecentsScreen(), AlbumsScreen()];

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lumina Gallery"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[400],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<MenuItems>(
            onSelected: (MenuItems item) {
              if (item == MenuItems.settings) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
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
        items: [
          // All Photos
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: "Photos"),

          // Albums
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: "Albums",
          ),
        ],
      ),
    );
  }
}
