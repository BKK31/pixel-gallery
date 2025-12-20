import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/home_screen.dart';
import 'package:lumina_gallery/screens/recents_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        '/home': (context) => HomeScreen(),
        '/albums': (context) => AlbumsScreen(),
        '/recent': (context) => RecentsScreen(),
      },
    );
  }
}
