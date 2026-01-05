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

  bool _isSelecting = false;
  int _selectedCount = 0;

  late final GlobalKey<RecentsScreenState> _recentsKey;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _recentsKey = GlobalKey<RecentsScreenState>();

    _pages = [
      RecentsScreen(key: _recentsKey, onSelectionChanged: _onSelectionChanged),
      const AlbumsScreen(),
    ];

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

  void _onSelectionChanged(bool selecting, int count) {
    setState(() {
      _isSelecting = selecting;
      _selectedCount = count;
    });
  }

  void _clearSelection() {
    _recentsKey.currentState?.clearSelections();
    setState(() {
      _isSelecting = false;
      _selectedCount = 0;
    });
  }

  void _deleteSelected() {
    _recentsKey.currentState?.deleteSelected();
  }

  void _shareSelected() {
    _recentsKey.currentState?.shareSelected();
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
        builder: (_) => SettingsScreen(onThemeChange: widget.onThemeRefresh),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBarM3E(
      title: _isSelecting
          ? Text(
              "${_selectedCount} Selected",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            )
          : Text(
              "Pixel Gallery",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
      centerTitle: _isSelecting ? false : true,
      shapeFamily: AppBarM3EShapeFamily.round,
      density: AppBarM3EDensity.regular,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: false,
      leading: _isSelecting
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            )
          : const Icon(null),
      actions: _isSelecting
          ? [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareSelected,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelected,
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _openSettings,
              ),
            ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: FutureBuilder<void>(
        future: _initSettings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return BottomBar(
            fit: StackFit.expand,
            icon: (width, height) =>
                Center(child: Icon(Icons.arrow_upward_rounded, size: width)),
            borderRadius: BorderRadius.circular(500),
            duration: const Duration(seconds: 1),
            curve: Curves.decelerate,
            showIcon: true,
            width: MediaQuery.of(context).size.width * 0.8,
            barColor: Theme.of(
              context,
            ).colorScheme.inversePrimary.withOpacity(0.2),
            start: 2,
            end: 0,
            offset: 10,
            barAlignment: Alignment.bottomCenter,
            iconHeight: 35,
            iconWidth: 35,
            hideOnScroll: true,
            respectSafeArea: true,
            body: (context, controller) => TabBarView(
              controller: _tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: _pages,
            ),
            child: TabBar(
              controller: _tabController,
              onTap: _navigateBottomBar,
              dividerColor: Colors.transparent,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 6),
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
          );
        },
      ),
    );
  }
}
