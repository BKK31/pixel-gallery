import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/recents_screen.dart';
import 'package:lumina_gallery/screens/settings_screen.dart';
import 'package:lumina_gallery/services/settings_service.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeRefresh;
  const HomeScreen({super.key, this.onThemeRefresh});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _selectedIndex;
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

    // Load initial tab synchronously from pre-initialized service
    _selectedIndex = SettingsService().startupAtAlbums ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedIndex,
    );

    WidgetsBinding.instance.addObserver(this);

    // Permissions are handled inside the sub-screens on demand or in background
    // No need to block the entire HomeScreen build.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh recents if needed
      _recentsKey.currentState?.refresh();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveTopEntries();
    }
  }

  void _saveTopEntries() {
    final recentsState = _recentsKey.currentState;
    if (recentsState != null) {
      final visibleIds = recentsState.getVisibleEntryIds();
      if (visibleIds.isNotEmpty) {
        SettingsService().topEntryIds = visibleIds;
      }
    }
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
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            )
          : const Text(
              "Pixel Gallery",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
      centerTitle: !_isSelecting,
      shapeFamily: AppBarM3EShapeFamily.round,
      density: AppBarM3EDensity.regular,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: false,
      leading: _isSelecting
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            )
          : Icon(null),
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelecting) {
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: BottomBar(
          fit: StackFit.expand,
          icon: (width, height) =>
              Center(child: Icon(Icons.arrow_upward_rounded, size: width)),
          borderRadius: BorderRadius.circular(500),
          duration: const Duration(seconds: 1),
          curve: Curves.decelerate,
          showIcon: true,
          width: MediaQuery.of(context).size.width * 0.4,
          barColor: Color.lerp(
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.surface,
            0.92,
          )!,
          start: 2,
          end: 0,
          offset: 8,
          barAlignment: Alignment.bottomCenter,
          iconHeight: 35,
          iconWidth: 35,
          hideOnScroll: true,
          onBottomBarHidden: () {},
          respectSafeArea: true,
          body: (context, controller) => TabBarView(
            controller: _tabController,
            dragStartBehavior: DragStartBehavior.down,
            physics: PageScrollPhysics(),
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
        ),
      ),
    );
  }
}
