import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/photos_screen.dart';
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

  final List _pages = [PhotosScreen(), AlbumsScreen()];

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.center,
          child: Text(
            "\t\t\t\t\t\t\t\t\tLumina Gallery",
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.deepPurple[400],
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

          // Albumns
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: "Albumns",
          ),
        ],
      ),
    );
  }
}
