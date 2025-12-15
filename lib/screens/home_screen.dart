import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/photos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
        title: Center(
          child: Text("Lumina Gallery", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.deepPurple[400],
        actions: [
          Icon(Icons.more_vert, color: Colors.white),
          // Padding(padding: EdgeInsetsGeometry.only(right: 5)),
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

