package com.pixel.gallery.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.PhotoAlbum
import androidx.compose.material.icons.outlined.Photo
import androidx.compose.material.icons.outlined.PhotoAlbum
import androidx.compose.material3.*
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.FloatingToolbarExitDirection
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.home.AlbumsScreen
import com.pixel.gallery.ui.settings.SettingsScreen
import com.pixel.gallery.ui.gallery.FavouritesScreen
import com.pixel.gallery.ui.gallery.TrashScreen
import com.pixel.gallery.ui.gallery.HiddenAlbumsScreen
import com.pixel.gallery.ui.gallery.PhotoScreen
import com.pixel.gallery.ui.locked.LockedFolderScreen
import com.pixel.gallery.ui.viewer.ViewerScreen
import com.pixel.gallery.ui.settings.ExcludedFoldersScreen
import com.pixel.gallery.ui.settings.LicensesScreen
import com.pixel.gallery.ui.theme.EmphasizedTypography
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.outlined.RestoreFromTrash
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.Lock
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel

// Height of the toolbar + gap, used to pad content so last items aren't hidden
private val FloatingBarHeight = 80.dp

sealed class Screen {
    object Home : Screen()
    object Settings : Screen()
    object Favourites : Screen()
    object Trash : Screen()
    object HiddenAlbums : Screen()
    object LockedFolder : Screen()
    data class Viewer(val initialId: Long, val source: ViewerSource = ViewerSource.All) : Screen()
    object ExcludedFolders : Screen()
    object Licenses : Screen()
    data class Photo(val albumName: String) : Screen()

    enum class ViewerSource { All, Favourites, Trash, Album }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun MainScaffold(
    photosViewModel: PhotosViewModel = hiltViewModel()
) {
    val allPhotos by photosViewModel.photos.collectAsState()
    val favourites by photosViewModel.favourites.collectAsState()
    val trash by photosViewModel.trashedMedia.collectAsState()
    val albums by photosViewModel.albums.collectAsState()
    
    // Simple navigation stack
    var navigationStack by remember { mutableStateOf(listOf<Screen>(Screen.Home)) }
    val currentScreen = navigationStack.last()
    
    val startupAtAlbums by photosViewModel.startupAtAlbums.collectAsState()
    var selectedTab by remember { mutableIntStateOf(0) }
    var hasInitializedTab by remember { mutableStateOf(false) }

    // Initialize tab based on preference once
    LaunchedEffect(startupAtAlbums) {
        if (!hasInitializedTab) {
            selectedTab = if (startupAtAlbums) 1 else 0
            hasInitializedTab = true
        }
    }

    var selectedIds by remember { mutableStateOf(setOf<Long>()) }
    
    val toggleSelection = { id: Long ->
        selectedIds = if (selectedIds.contains(id)) {
            selectedIds - id
        } else {
            selectedIds + id
        }
    }

    var showMenu by remember { mutableStateOf(false) }

    // System back button handling
    BackHandler(enabled = navigationStack.size > 1 || selectedIds.isNotEmpty()) {
        if (selectedIds.isNotEmpty()) {
            selectedIds = emptySet()
        } else {
            navigationStack = navigationStack.dropLast(1)
        }
    }

    // Reset selection when navigating
    LaunchedEffect(currentScreen) {
        selectedIds = emptySet()
    }

    // Scroll behavior: bar exits when scrolling down, returns when scrolling up
    val scrollBehavior = FloatingToolbarDefaults.exitAlwaysScrollBehavior(
        exitDirection = FloatingToolbarExitDirection.Bottom
    )

    val navBarPadding = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    val contentBottomPadding = FloatingBarHeight + 16.dp + navBarPadding
    val colorScheme = MaterialTheme.colorScheme
    val context = androidx.compose.ui.platform.LocalContext.current

    val selectedEntries = remember(selectedIds, allPhotos, trash) {
        (allPhotos + trash).filter { selectedIds.contains(it.contentId) }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0),
        topBar = {
            if (selectedIds.isNotEmpty()) {
                // Contextual Top Bar for Selection
                TopAppBar(
                    title = { Text("${selectedIds.size} selected") },
                    navigationIcon = {
                        IconButton(onClick = { selectedIds = emptySet() }) {
                            Icon(Icons.Default.Close, contentDescription = "Clear selection")
                        }
                    },
                    actions = {
                        if (currentScreen == Screen.Trash) {
                            IconButton(onClick = { 
                                photosViewModel.restoreMediaBulk(selectedEntries.map { it.uri })
                                selectedIds = emptySet()
                            }) {
                                Icon(Icons.Outlined.RestoreFromTrash, contentDescription = "Restore")
                            }
                            IconButton(onClick = { 
                                photosViewModel.deleteMediaBulk(selectedEntries.map { it.uri })
                                selectedIds = emptySet()
                            }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete permanently")
                            }
                        } else {
                            IconButton(onClick = { 
                                val uris = selectedEntries.map { android.net.Uri.parse(it.uri) }
                                val intent = android.content.Intent(android.content.Intent.ACTION_SEND_MULTIPLE).apply {
                                    type = "*/*" // Could be more specific if all are same type
                                    putParcelableArrayListExtra(android.content.Intent.EXTRA_STREAM, ArrayList(uris))
                                    addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                context.startActivity(android.content.Intent.createChooser(intent, "Share Media"))
                            }) {
                                Icon(Icons.Default.Share, contentDescription = "Share")
                            }

                            IconButton(onClick = { 
                                photosViewModel.moveToTrashBulk(selectedEntries.map { it.uri })
                                selectedIds = emptySet()
                            }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete")
                            }
                        }
                    }
                )
            } else if (currentScreen == Screen.Home) {
                CenterAlignedTopAppBar(
                    title = {
                        Text(
                            text = "Pixel Gallery",
                            style = EmphasizedTypography.HeadlineMedium
                        )
                    },
                    actions = {
                        IconButton(onClick = { showMenu = !showMenu }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "More")
                        }
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Hidden Albums") },
                                onClick = { 
                                    showMenu = false
                                    navigationStack = navigationStack + Screen.HiddenAlbums 
                                },
                                leadingIcon = { Icon(Icons.Outlined.VisibilityOff, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Locked Folder") },
                                onClick = { 
                                    showMenu = false
                                    navigationStack = navigationStack + Screen.LockedFolder 
                                },
                                leadingIcon = { Icon(Icons.Outlined.Lock, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Settings") },
                                onClick = { 
                                    showMenu = false
                                    navigationStack = navigationStack + Screen.Settings 
                                },
                                leadingIcon = { Icon(Icons.Outlined.Settings, contentDescription = null) }
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = colorScheme.surface,
                        titleContentColor = colorScheme.onSurface
                    ),
                    windowInsets = WindowInsets.statusBars
                )
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Screen content management
            when (currentScreen) {
                Screen.Home -> {
                    when (selectedTab) {
                        0 -> PhotosScreen(
                            photos = allPhotos,
                            onNavigateToViewer = { id -> navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.All) },
                            selectedIds = selectedIds,
                            onToggleSelection = toggleSelection,
                            bottomPadding = contentBottomPadding
                        )
                        1 -> AlbumsScreen(
                            albums = albums,
                            bottomPadding = contentBottomPadding,
                            onNavigateToFavourites = { navigationStack = navigationStack + Screen.Favourites },
                            onNavigateToTrash = { navigationStack = navigationStack + Screen.Trash },
                            onNavigateToAlbum = { name -> navigationStack = navigationStack + Screen.Photo(name) }
                        )
                    }
                }
                Screen.Settings -> SettingsScreen(
                    onBack = { navigationStack = navigationStack.dropLast(1) },
                    onNavigateToExcludedFolders = { navigationStack = navigationStack + Screen.ExcludedFolders },
                    onNavigateToLicenses = { navigationStack = navigationStack + Screen.Licenses }
                )
                Screen.Favourites -> FavouritesScreen(
                    onBack = { navigationStack = navigationStack.dropLast(1) },
                    onNavigateToViewer = { id -> navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.Favourites) },
                    selectedIds = selectedIds,
                    onToggleSelection = toggleSelection
                )
                Screen.Trash -> TrashScreen(
                    onBack = { navigationStack = navigationStack.dropLast(1) },
                    onNavigateToViewer = { id -> navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.Trash) },
                    selectedIds = selectedIds,
                    onToggleSelection = toggleSelection
                )
                Screen.HiddenAlbums -> HiddenAlbumsScreen(onBack = { navigationStack = navigationStack.dropLast(1) })
                Screen.LockedFolder -> LockedFolderScreen(onBack = { navigationStack = navigationStack.dropLast(1) })
                is Screen.Viewer -> {
                    val viewer = currentScreen as Screen.Viewer
                    val photosForViewer = when (viewer.source) {
                        Screen.ViewerSource.All -> allPhotos
                        Screen.ViewerSource.Favourites -> favourites
                        Screen.ViewerSource.Trash -> trash
                        Screen.ViewerSource.Album -> allPhotos // Simplified
                    }
                    ViewerScreen(
                        initialId = viewer.initialId,
                        photos = photosForViewer,
                        onBack = { navigationStack = navigationStack.dropLast(1) }
                    )
                }
                Screen.ExcludedFolders -> ExcludedFoldersScreen(onBack = { navigationStack = navigationStack.dropLast(1) })
                Screen.Licenses -> LicensesScreen(onBack = { navigationStack = navigationStack.dropLast(1) })
                is Screen.Photo -> {
                    val albumName = (currentScreen as Screen.Photo).albumName
                    PhotoScreen(
                        albumName = albumName,
                        onBack = { navigationStack = navigationStack.dropLast(1) },
                        onNavigateToViewer = { id -> navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.Album) },
                        selectedIds = selectedIds,
                        onToggleSelection = toggleSelection
                    )
                }
            }

            // Only show the floating bar on the Home screen
            if (currentScreen == Screen.Home) {
                HorizontalFloatingToolbar(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .windowInsetsPadding(WindowInsets.navigationBars)
                        .padding(bottom = 16.dp),
                    expanded = true,
                    scrollBehavior = scrollBehavior,
                    colors = FloatingToolbarDefaults.standardFloatingToolbarColors(),
                    content = {
                        val tabs = listOf(
                            NavTab("Photos", Icons.Filled.Photo, Icons.Outlined.Photo),
                            NavTab("Albums", Icons.Filled.PhotoAlbum, Icons.Outlined.PhotoAlbum)
                        )

                        tabs.forEachIndexed { index, tab ->
                            val isSelected = selectedTab == index
                            
                            // Using a pill-shaped item that shows a label when selected
                            Surface(
                                onClick = { selectedTab = index },
                                shape = FloatingToolbarDefaults.ContainerShape,
                                color = if (isSelected) colorScheme.primaryContainer else colorScheme.surface,
                                contentColor = if (isSelected) colorScheme.onPrimaryContainer else colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 4.dp)
                            ) {
                                Row(
                                    modifier = Modifier
                                        .padding(horizontal = 12.dp, vertical = 8.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = if (isSelected) tab.selectedIcon else tab.unselectedIcon,
                                        contentDescription = tab.label,
                                        modifier = Modifier.size(24.dp)
                                    )
                                    AnimatedVisibility(visible = isSelected) {
                                        Text(
                                            text = tab.label,
                                            style = MaterialTheme.typography.labelLarge,
                                            modifier = Modifier.padding(start = 8.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                )
            }
        }
    }
}

private data class NavTab(
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)
