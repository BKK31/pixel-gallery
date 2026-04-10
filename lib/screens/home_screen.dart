import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:lumina_gallery/screens/albums_screen.dart';
import 'package:lumina_gallery/screens/recents_screen.dart';
import 'package:lumina_gallery/screens/settings_screen.dart';
import 'package:lumina_gallery/screens/hidden_albums_screen.dart';
import 'package:lumina_gallery/screens/locked_folder_screen.dart';
import 'package:lumina_gallery/services/settings_service.dart';
import 'package:lumina_gallery/services/media_service.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:lumina_gallery/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeRefresh;
  final VoidCallback? onLanguageRefresh;
  const HomeScreen({super.key, this.onThemeRefresh, this.onLanguageRefresh});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _selectedIndex;
  late TabController _tabController;

  // Recents selection
  bool _isSelecting = false;
  int _selectedCount = 0;

  // Albums selection
  bool _isAlbumSelecting = false;
  int _albumSelectedCount = 0;

  late final GlobalKey<RecentsScreenState> _recentsKey;
  late final GlobalKey<AlbumsScreenState> _albumsKey;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _recentsKey = GlobalKey<RecentsScreenState>();
    _albumsKey = GlobalKey<AlbumsScreenState>();

    _pages = [
      RecentsScreen(key: _recentsKey, onSelectionChanged: _onSelectionChanged),
      AlbumsScreen(
        key: _albumsKey,
        onSelectionChanged: _onAlbumSelectionChanged,
      ),
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
      // Trigger native MediaStore re-sync to pick up out-of-band file manager changes
      MediaService().triggerBackgroundSync();
      // Refresh active tab if needed
      if (_selectedIndex == 0) {
        _recentsKey.currentState?.refresh();
      }
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

  void _onAlbumSelectionChanged(bool selecting, int count) {
    setState(() {
      _isAlbumSelecting = selecting;
      _albumSelectedCount = count;
    });
  }

  void _clearSelection() {
    _recentsKey.currentState?.clearSelections();
    _albumsKey.currentState?.clearSelections();
    setState(() {
      _isSelecting = false;
      _selectedCount = 0;
      _isAlbumSelecting = false;
      _albumSelectedCount = 0;
    });
  }

  void _deleteSelected() {
    _recentsKey.currentState?.deleteSelected();
  }

  void _lockSelected() {
    _recentsKey.currentState?.lockSelected();
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
        builder: (_) => SettingsScreen(
          onThemeChange: widget.onThemeRefresh,
          onLanguageChange: widget.onLanguageRefresh,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Album selection mode (tab index 1)
    if (_isAlbumSelecting && _selectedIndex == 1) {
      return _buildAlbumSelectionAppBar(context);
    }
    // Photo selection mode (tab index 0)
    return AppBarM3E(
      title: _isSelecting
          ? Text(
              AppLocalizations.of(context)!.homeSelectedCount(_selectedCount),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            )
          : Text(
              AppLocalizations.of(context)!.appTitle,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteSelected();
                  } else if (value == 'lock') {
                    _lockSelected();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(AppLocalizations.of(context)!.homeDelete),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'lock',
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(AppLocalizations.of(context)!.homeLock),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ]
          : [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'settings') {
                    _openSettings();
                  } else if (value == 'hidden_albums') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HiddenAlbumsScreen(),
                      ),
                    );
                  } else if (value == 'locked_folder') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LockedFolderScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: const Icon(Icons.settings),
                      title: Text(AppLocalizations.of(context)!.settingsTitle),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hidden_albums',
                    child: ListTile(
                      leading: const Icon(Icons.visibility_off),
                      title: Text(AppLocalizations.of(context)!.homeHiddenAlbums),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'locked_folder',
                    child: ListTile(
                      leading: const Icon(Icons.lock),
                      title: Text(AppLocalizations.of(context)!.homeLockedFolder),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  PreferredSizeWidget _buildAlbumSelectionAppBar(BuildContext context) {
    return AppBarM3E(
      title: Text(
        AppLocalizations.of(context)!.homeSelectedCount(_albumSelectedCount),
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      shapeFamily: AppBarM3EShapeFamily.round,
      density: AppBarM3EDensity.regular,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.visibility_off),
          tooltip: 'Hide / Unhide',
          onPressed: () => _albumsKey.currentState?.hideSelected(),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete contents',
          onPressed: () => _albumsKey.currentState?.deleteSelected(),
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
