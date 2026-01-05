import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/recents_screen.dart';
import 'package:lumina_gallery/screens/settings_screen.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeRefresh;
  const HomeScreen({super.key, this.onThemeRefresh});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late Future<void> _initSettings;
  late TabController _tabController;
  final List<Widget> _pages = [RecentsScreen(), AlbumsScreen()];

  @override
  void initState() {
    super.initState();
    _initSettings = _loadInitialSettings();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadInitialSettings() async {
    final bool startAlbum = await SettingsScreen.getStartupAtAlbums();
    setState(() {
      _selectedIndex = startAlbum ? 1 : 0;
      _tabController.index = _selectedIndex;
    });
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.index = index;
    });
  }

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          appBar: AppBarM3E(
            title: const Text(
              "Pixel Gallery",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            shapeFamily: AppBarM3EShapeFamily.round,
            density: AppBarM3EDensity.regular,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                onPressed: () {
                  _openSettings();
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: BottomBar(
            fit: StackFit.expand,
            icon: (width, height) => Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: null,
                icon: Icon(Icons.arrow_upward_rounded, size: width),
              ),
            ),
            borderRadius: BorderRadius.circular(500),
            duration: const Duration(seconds: 1),
            curve: Curves.decelerate,
            showIcon: true,
            width: MediaQuery.of(context).size.width * 0.8,
            barColor: Theme.of(context).colorScheme.surface,
            start: 2,
            end: 0,
            offset: 10,
            barAlignment: Alignment.bottomCenter,
            iconHeight: 35,
            iconWidth: 35,
            reverse: false,
            hideOnScroll: true,
            scrollOpposite: false,
            respectSafeArea: true,
            onBottomBarHidden: () {},
            onBottomBarShown: () {},
            body: (context, controller) => TabBarView(
              controller: _tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: _pages,
            ),
            child: TabBar(
              controller: _tabController,
              onTap: _navigateBottomBar,
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              tabs: const [
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(child: Icon(Icons.photo)),
                ),
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(child: Icon(Icons.photo_album)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
