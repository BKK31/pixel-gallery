import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/home_screen.dart';
import 'package:lumina_gallery/screens/photos_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: HomeScreen(),
      routes: {
        '/home':(context) => HomeScreen(),
        '/albums': (context) => AlbumsScreen(),
        '/photos':(context) => PhotosScreen(),
      },
    );
  }
}