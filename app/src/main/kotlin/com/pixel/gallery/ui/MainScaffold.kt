package com.pixel.gallery.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.PhotoAlbum
import androidx.compose.material.icons.outlined.Photo
import androidx.compose.material.icons.outlined.PhotoAlbum
import androidx.compose.material3.*
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.FloatingToolbarExitDirection
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.pixel.gallery.model.Album
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
import androidx.compose.ui.res.stringResource
import com.pixel.gallery.R
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.core.content.FileProvider
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.ui.components.DeleteConfirmationDialog
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.CreateNewFolder
import androidx.compose.foundation.clickable
import android.widget.Toast

import android.os.Parcelable
import kotlinx.parcelize.Parcelize
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.ui.input.nestedscroll.nestedScroll
import kotlinx.coroutines.launch

// Height of the toolbar + gap, used to pad content so last items aren't hidden
private val FloatingBarHeight = 80.dp

sealed class Screen : Parcelable {
    @Parcelize object Home : Screen()
    @Parcelize object Settings : Screen()
    @Parcelize object Favourites : Screen()
    @Parcelize object Trash : Screen()
    @Parcelize object HiddenAlbums : Screen()
    @Parcelize object LockedFolder : Screen()
    @Parcelize data class Viewer(
        val initialId: Long, 
        val source: ViewerSource = ViewerSource.All,
        val albumName: String? = null,
        val externalUri: String? = null,
        val externalMimeType: String? = null
    ) : Screen()
    @Parcelize object ExcludedFolders : Screen()
    @Parcelize object Licenses : Screen()
    @Parcelize data class Photo(val source: com.pixel.gallery.ui.gallery.AlbumSource) : Screen()

    enum class ViewerSource { All, Favourites, Trash, Album, Vault, External }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun MainScaffold(
    photosViewModel: PhotosViewModel = hiltViewModel()
) {
    val allPhotos by photosViewModel.photos.collectAsState()
    val groupedPhotos by photosViewModel.groupedPhotos.collectAsState()
    val favourites by photosViewModel.favourites.collectAsState()
    val groupedFavourites by photosViewModel.groupedFavourites.collectAsState()
    val trash by photosViewModel.trashedMedia.collectAsState()
    val groupedTrash by photosViewModel.groupedTrashedMedia.collectAsState()
    val vault by photosViewModel.vaultEntries.collectAsState()
    val groupedVault by photosViewModel.groupedVaultEntries.collectAsState()
    val albums by photosViewModel.albums.collectAsState()
    val gridColumns by photosViewModel.gridColumns.collectAsState()
    val externalMedia by photosViewModel.externalMedia.collectAsState()
    
    // Simple navigation stack
    var navigationStack by rememberSaveable { mutableStateOf(listOf<Screen>(Screen.Home)) }

    LaunchedEffect(externalMedia) {
        externalMedia?.let { media ->
            navigationStack = listOf(Screen.Home, Screen.Viewer(initialId = -1L, source = Screen.ViewerSource.External, externalUri = media.uri, externalMimeType = media.mimeType))
            photosViewModel.clearExternalMediaUri()
        }
    }

    val currentScreen = navigationStack.last()
    
    // Hoisted Grid States for persistence
    val recentsGridState = rememberLazyGridState()
    val albumsGridState = rememberLazyGridState()
    val favouritesGridState = rememberLazyGridState()
    val trashGridState = rememberLazyGridState()
    val vaultGridState = rememberLazyGridState()
    val albumPhotoGridState = rememberLazyGridState() // Shared for individual albums
    
    val startupAtAlbums by photosViewModel.startupAtAlbums.collectAsState()
    val confirmTrash by photosViewModel.confirmTrash.collectAsState()
    val confirmDelete by photosViewModel.confirmDelete.collectAsState()

    var showDeleteConfirmDialog by remember { mutableStateOf(false) }
    var isPermanentDelete by remember { mutableStateOf(false) }
    var pendingDeleteEntries by remember { mutableStateOf<List<MediaEntry>>(emptyList()) }

    val homePagerState = rememberPagerState(pageCount = { 2 })
    val scope = rememberCoroutineScope()

    // Initialize tab based on preference once
    var hasInitializedTab by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(startupAtAlbums) {
        if (!hasInitializedTab) {
            val initialPage = if (startupAtAlbums) 1 else 0
            homePagerState.scrollToPage(initialPage)
            hasInitializedTab = true
        }
    }

    var selectedIds by remember { mutableStateOf(setOf<Long>()) }
    var showMoveToAlbumDialog by remember { mutableStateOf(false) }
    var isMoveOperation by remember { mutableStateOf(true) }
    
    var selectedAlbumsForActions by remember { mutableStateOf<Set<Album>>(emptySet()) }
    var showAddPhotosToNewAlbumDialog by remember { mutableStateOf(false) }
    var newAlbumCreatedName by remember { mutableStateOf("") }

    val toggleSelection = { id: Long ->
        selectedIds = if (selectedIds.contains(id)) {
            selectedIds - id
        } else {
            selectedIds + id
        }
    }

    val updateSelection = { ids: Set<Long> ->
        selectedIds = ids
    }

    val toggleSelectionAlbum = { album: Album ->
        selectedAlbumsForActions = if (selectedAlbumsForActions.contains(album)) {
            selectedAlbumsForActions - album
        } else {
            selectedAlbumsForActions + album
        }
    }

    var showMenu by remember { mutableStateOf(false) }

    // System back button handling
    BackHandler(enabled = navigationStack.size > 1 || selectedIds.isNotEmpty() || selectedAlbumsForActions.isNotEmpty()) {
        if (selectedIds.isNotEmpty()) {
            selectedIds = emptySet()
        } else if (selectedAlbumsForActions.isNotEmpty()) {
            selectedAlbumsForActions = emptySet()
        } else {
            navigationStack = navigationStack.dropLast(1)
        }
    }

    // Reset selection when navigating
    LaunchedEffect(currentScreen) {
        selectedIds = emptySet()
        selectedAlbumsForActions = emptySet()
    }

    // Scroll behavior: bar exits when scrolling down, returns when scrolling up
    val scrollBehavior = FloatingToolbarDefaults.exitAlwaysScrollBehavior(
        exitDirection = FloatingToolbarExitDirection.Bottom
    )

    // Window Insets
    val systemBarsPadding = WindowInsets.systemBars.asPaddingValues()
    val navBarPadding = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    val contentBottomPadding = if (currentScreen == Screen.Home) {
        FloatingBarHeight + 16.dp + navBarPadding
    } else {
        navBarPadding + 16.dp
    }
    
    val colorScheme = MaterialTheme.colorScheme
    val context = androidx.compose.ui.platform.LocalContext.current

    val selectedEntries = remember(selectedIds, allPhotos, trash, vault) {
        (allPhotos + trash + vault).filter { selectedIds.contains(it.contentId) }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0), // Manual padding for full control
        modifier = Modifier.nestedScroll(scrollBehavior),
        topBar = {
            if (selectedIds.isNotEmpty()) {
                val currentPhotosForSelectAll = remember(currentScreen, allPhotos, favourites, trash, vault) {
                    when (currentScreen) {
                        Screen.Home -> allPhotos
                        Screen.Favourites -> favourites
                        Screen.Trash -> trash
                        Screen.LockedFolder -> vault
                        is Screen.Photo -> {
                            when (val source = (currentScreen as Screen.Photo).source) {
                                is com.pixel.gallery.ui.gallery.AlbumSource.Recents -> allPhotos
                                is com.pixel.gallery.ui.gallery.AlbumSource.Favourites -> favourites
                                is com.pixel.gallery.ui.gallery.AlbumSource.Folder -> {
                                    allPhotos.filter { java.io.File(it.path).parentFile?.name == source.name }
                                }
                            }
                        }
                        else -> emptyList()
                    }
                }
                
                Surface(
                    color = MaterialTheme.colorScheme.surface,
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "${selectedIds.size} selected",
                                style = MaterialTheme.typography.titleLarge,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            val allSelected = currentPhotosForSelectAll.isNotEmpty() && 
                                    currentPhotosForSelectAll.all { selectedIds.contains(it.contentId) }
                            
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier
                                    .clickable {
                                        if (allSelected) {
                                            selectedIds = emptySet()
                                        } else {
                                            selectedIds = currentPhotosForSelectAll.map { it.contentId }.toSet()
                                        }
                                    }
                                    .padding(vertical = 8.dp)
                            ) {
                                Icon(
                                    imageVector = if (allSelected) Icons.Filled.CheckCircle else Icons.Outlined.RadioButtonUnchecked,
                                    contentDescription = "Select All",
                                    tint = if (allSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(24.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "All",
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            
                            TextButton(
                                onClick = { selectedIds = emptySet() }
                            ) {
                                Text(
                                    text = stringResource(R.string.cancel),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                }
            } else if (currentScreen == Screen.Home) {
                CenterAlignedTopAppBar(
                    title = {
                        Text(
                            text = if (homePagerState.currentPage == 0) stringResource(R.string.photos) else stringResource(R.string.albums),
                            style = EmphasizedTypography.HeadlineMedium
                        )
                    },
                    actions = {
                        if (homePagerState.currentPage == 1) {
                            var showCreateAlbumDialogInHome by remember { mutableStateOf(false) }
                            var newAlbumNameInputInHome by remember { mutableStateOf("") }
                            IconButton(onClick = { showCreateAlbumDialogInHome = true }) {
                                Icon(Icons.Default.Add, contentDescription = stringResource(R.string.create_album_desc))
                            }
                            if (showCreateAlbumDialogInHome) {
                                AlertDialog(
                                    onDismissRequest = { showCreateAlbumDialogInHome = false },
                                    title = { Text(stringResource(R.string.create_new_album)) },
                                    text = {
                                        OutlinedTextField(
                                            value = newAlbumNameInputInHome,
                                            onValueChange = { newAlbumNameInputInHome = it },
                                            label = { Text(stringResource(R.string.album_name_label)) },
                                            singleLine = true,
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                    },
                                    confirmButton = {
                                        TextButton(
                                            onClick = {
                                                val name = newAlbumNameInputInHome.trim()
                                                if (name.isNotEmpty()) {
                                                    photosViewModel.createNewAlbum(name)
                                                    showCreateAlbumDialogInHome = false
                                                    newAlbumNameInputInHome = ""
                                                    newAlbumCreatedName = name
                                                    showAddPhotosToNewAlbumDialog = true
                                                }
                                            },
                                            enabled = newAlbumNameInputInHome.trim().isNotEmpty()
                                        ) {
                                            Text(stringResource(R.string.create_action))
                                        }
                                    },
                                    dismissButton = {
                                        TextButton(onClick = { showCreateAlbumDialogInHome = false }) {
                                            Text(stringResource(R.string.cancel))
                                        }
                                    }
                                )
                            }
                        }
                        IconButton(onClick = { showMenu = !showMenu }) {
                            Icon(Icons.Default.MoreVert, contentDescription = stringResource(R.string.more))
                        }
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.hidden_albums)) },
                                onClick = { 
                                    showMenu = false
                                    navigationStack = navigationStack + Screen.HiddenAlbums 
                                },
                                leadingIcon = { Icon(Icons.Outlined.VisibilityOff, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.locked_folder)) },
                                onClick = { 
                                    showMenu = false
                                    navigationStack = navigationStack + Screen.LockedFolder 
                                },
                                leadingIcon = { Icon(Icons.Outlined.Lock, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.settings)) },
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
                .padding(top = if (currentScreen is Screen.Viewer) 0.dp else innerPadding.calculateTopPadding())
        ) {
            // Screen content management
            when (currentScreen) {
                Screen.Home -> {
                    HorizontalPager(
                        state = homePagerState,
                        modifier = Modifier.fillMaxSize(),
                        userScrollEnabled = selectedIds.isEmpty() // Disable swiping during selection
                    ) { page ->
                        when (page) {
                            0 -> PhotosScreen(
                                items = groupedPhotos,
                                onNavigateToViewer = { id -> navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.All) },
                                selectedIds = selectedIds,
                                onSelectionChange = updateSelection,
                                onToggleSelection = toggleSelection,
                                columns = gridColumns,
                                onColumnsChange = { photosViewModel.setGridColumns(it) },
                                bottomPadding = contentBottomPadding,
                                state = recentsGridState
                            )
                            1 -> AlbumsScreen(
                                albums = albums,
                                bottomPadding = contentBottomPadding,
                                gridState = albumsGridState,
                                onNavigateToFavourites = { navigationStack = navigationStack + Screen.Favourites },
                                onNavigateToTrash = { navigationStack = navigationStack + Screen.Trash },
                                onNavigateToAlbum = { name -> navigationStack = navigationStack + Screen.Photo(com.pixel.gallery.ui.gallery.AlbumSource.Folder(name)) },
                                onExclude = { path -> photosViewModel.addExcludedFolder(path) },
                                onHide = { path -> photosViewModel.addHiddenFolder(path) },
                                onLongClickAlbum = { album -> selectedAlbumsForActions = setOf(album) },
                                selectedAlbums = selectedAlbumsForActions,
                                onSelectionChangeAlbums = { albums -> selectedAlbumsForActions = albums },
                                onToggleSelectionAlbum = toggleSelectionAlbum
                            )
                        }
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
                    onSelectionChange = updateSelection,
                    onToggleSelection = toggleSelection,
                    items = groupedFavourites,
                    gridState = favouritesGridState
                )
                Screen.Trash -> TrashScreen(
                    onBack = { navigationStack = navigationStack.dropLast(1) },
                    onNavigateToViewer = { id -> navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.Trash) },
                    selectedIds = selectedIds,
                    onSelectionChange = updateSelection,
                    onToggleSelection = toggleSelection,
                    items = groupedTrash,
                    gridState = trashGridState
                )
                Screen.HiddenAlbums -> HiddenAlbumsScreen(onBack = { navigationStack = navigationStack.dropLast(1) })
                Screen.LockedFolder -> LockedFolderScreen(
                    onBack = { navigationStack = navigationStack.dropLast(1) },
                    onNavigateToViewer = { id -> navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.Vault) },
                    selectedIds = selectedIds,
                    onSelectionChange = updateSelection,
                    onToggleSelection = toggleSelection,
                    items = groupedVault
                )
                is Screen.Viewer -> {
                    val viewer = currentScreen as Screen.Viewer
                    val photosForViewer = when (viewer.source) {
                        Screen.ViewerSource.All -> allPhotos
                        Screen.ViewerSource.Favourites -> favourites
                        Screen.ViewerSource.Trash -> trash
                        Screen.ViewerSource.Vault -> vault
                        Screen.ViewerSource.Album -> {
                            allPhotos.filter { 
                                val file = java.io.File(it.path)
                                file.parentFile?.name == viewer.albumName
                            }
                        }
                        Screen.ViewerSource.External -> {
                            val uri = viewer.externalUri ?: ""
                            val mimeType = viewer.externalMimeType ?: "image/*"
                            listOf(
                                com.pixel.gallery.data.local.entity.MediaEntry(
                                    contentId = -1L,
                                    path = uri,
                                    uri = uri,
                                    sourceMimeType = mimeType,
                                    width = 0,
                                    height = 0,
                                    sourceRotationDegrees = 0,
                                    sizeBytes = 0,
                                    dateAddedSecs = 0,
                                    dateModifiedMillis = 0,
                                    isTrashed = false,
                                    bestTimestamp = 0L
                                )
                            )
                        }
                    }
                    ViewerScreen(
                        initialId = viewer.initialId,
                        photos = photosForViewer,
                        isVault = viewer.source == Screen.ViewerSource.Vault,
                        onBack = { navigationStack = navigationStack.dropLast(1) }
                    )
                }
                Screen.ExcludedFolders -> ExcludedFoldersScreen(onBack = { navigationStack = navigationStack.dropLast(1) })
                Screen.Licenses -> LicensesScreen(onBack = { navigationStack = navigationStack.dropLast(1) })
                is Screen.Photo -> {
                    val source = (currentScreen as Screen.Photo).source
                    PhotoScreen(
                        currentSource = source,
                        onBack = { navigationStack = navigationStack.dropLast(1) },
                        onNavigateToViewer = { id -> 
                            val (viewerSource, viewerAlbumName) = when (source) {
                                is com.pixel.gallery.ui.gallery.AlbumSource.Recents -> Screen.ViewerSource.All to null
                                is com.pixel.gallery.ui.gallery.AlbumSource.Favourites -> Screen.ViewerSource.Favourites to null
                                is com.pixel.gallery.ui.gallery.AlbumSource.Folder -> Screen.ViewerSource.Album to source.name
                            }
                            navigationStack = navigationStack + Screen.Viewer(id, viewerSource, viewerAlbumName) 
                        },
                        onSourceChange = { newSource ->
                            navigationStack = navigationStack.dropLast(1) + Screen.Photo(newSource)
                        },
                        selectedIds = selectedIds,
                        onSelectionChange = updateSelection,
                        onToggleSelection = toggleSelection,
                        gridState = albumPhotoGridState
                    )
                }
            }

            // Only show the floating bar on the Home screen
            if (currentScreen == Screen.Home && selectedIds.isEmpty() && selectedAlbumsForActions.isEmpty()) {
                var showMoreMenu by remember { mutableStateOf(false) }
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
                            NavTab(stringResource(R.string.photos), Icons.Filled.Photo, Icons.Outlined.Photo),
                            NavTab(stringResource(R.string.albums), Icons.Filled.PhotoAlbum, Icons.Outlined.PhotoAlbum)
                        )

                        tabs.forEachIndexed { index, tab ->
                            val isSelected = homePagerState.currentPage == index

                            Surface(
                                onClick = {
                                    scope.launch {
                                        homePagerState.animateScrollToPage(index)
                                    }
                                },
                                shape = FloatingToolbarDefaults.ContainerShape,
                                color = if (isSelected) colorScheme.primaryContainer else colorScheme.surface,
                                contentColor = if (isSelected) colorScheme.onPrimaryContainer else colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 4.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
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

                        // More Button
                        Box {
                            Surface(
                                onClick = { showMoreMenu = true },
                                shape = FloatingToolbarDefaults.ContainerShape,
                                color = colorScheme.surface,
                                contentColor = colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 4.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Menu,
                                        contentDescription = stringResource(R.string.more),
                                        modifier = Modifier.size(24.dp)
                                    )
                                }
                            }
                            DropdownMenu(
                                expanded = showMoreMenu,
                                onDismissRequest = { showMoreMenu = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text(stringResource(R.string.favorites_title)) },
                                    onClick = {
                                        showMoreMenu = false
                                        navigationStack = navigationStack + Screen.Favourites
                                    },
                                    leadingIcon = { Icon(Icons.Outlined.FavoriteBorder, contentDescription = null) }
                                )
                                DropdownMenuItem(
                                    text = { Text(stringResource(R.string.recycle_bin)) },
                                    onClick = {
                                        showMoreMenu = false
                                        navigationStack = navigationStack + Screen.Trash
                                    },
                                    leadingIcon = { Icon(Icons.Outlined.DeleteOutline, contentDescription = null) }
                                )
                            }
                        }
                    }
                )
            }

            // Dialogs for album copy and move operations
            if (showMoveToAlbumDialog) {
                var showNewAlbumNameInput by remember { mutableStateOf(false) }
                var newAlbumNameInput by remember { mutableStateOf("") }
                
                val operationName = if (isMoveOperation) stringResource(R.string.move_action) else stringResource(R.string.copy_action)

                if (showNewAlbumNameInput) {
                    AlertDialog(
                        onDismissRequest = { showNewAlbumNameInput = false },
                        title = { Text(stringResource(R.string.create_new_album)) },
                        text = {
                            OutlinedTextField(
                                value = newAlbumNameInput,
                                onValueChange = { newAlbumNameInput = it },
                                label = { Text(stringResource(R.string.album_name_label)) },
                                singleLine = true,
                                modifier = Modifier.fillMaxWidth()
                            )
                        },
                        confirmButton = {
                            TextButton(
                                onClick = {
                                    val name = newAlbumNameInput.trim()
                                    if (name.isNotEmpty()) {
                                        showNewAlbumNameInput = false
                                        showMoveToAlbumDialog = false
                                        val entriesToMove = selectedEntries
                                        photosViewModel.copyOrMoveMedia(entriesToMove, name, isMove = isMoveOperation) { result ->
                                            val message = when {
                                                result.hasSuccess && result.hasFailure ->
                                                    context.getString(if (isMoveOperation) R.string.move_success_fail else R.string.copy_success_fail, result.succeeded, name, result.failed)
                                                result.hasSuccess ->
                                                    context.getString(if (isMoveOperation) R.string.move_success else R.string.copy_success, result.succeeded, name)
                                                result.skipped > 0 && !result.hasFailure ->
                                                    context.getString(if (isMoveOperation) R.string.no_items_moved else R.string.no_items_copied)
                                                else ->
                                                    context.getString(if (isMoveOperation) R.string.move_failed else R.string.copy_failed, entriesToMove.size)
                                            }
                                            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                                            if (result.hasSuccess) {
                                                selectedIds = emptySet()
                                            }
                                        }
                                    }
                                },
                                enabled = newAlbumNameInput.trim().isNotEmpty()
                            ) {
                                Text(operationName)
                            }
                        },
                        dismissButton = {
                            TextButton(onClick = { showNewAlbumNameInput = false }) {
                                Text(stringResource(R.string.cancel))
                            }
                        }
                    )
                } else {
                    AlertDialog(
                        onDismissRequest = { showMoveToAlbumDialog = false },
                        title = { 
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(if (isMoveOperation) stringResource(R.string.move_to_folder) else stringResource(R.string.copy_to_folder))
                                IconButton(onClick = { showNewAlbumNameInput = true }) {
                                    Icon(Icons.Default.Add, contentDescription = stringResource(R.string.create_album_desc))
                                }
                            }
                        },
                        text = {
                            LazyColumn(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                items(albums) { album ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable {
                                                showMoveToAlbumDialog = false
                                                val entriesToMove = selectedEntries
                                                photosViewModel.copyOrMoveMedia(entriesToMove, album.path, isMove = isMoveOperation) { result ->
                                                    val message = when {
                                                        result.hasSuccess && result.hasFailure ->
                                                            context.getString(if (isMoveOperation) R.string.move_success_fail else R.string.copy_success_fail, result.succeeded, album.name, result.failed)
                                                        result.hasSuccess ->
                                                            context.getString(if (isMoveOperation) R.string.move_success else R.string.copy_success, result.succeeded, album.name)
                                                        result.skipped > 0 && !result.hasFailure ->
                                                            context.getString(if (isMoveOperation) R.string.no_items_moved else R.string.no_items_copied)
                                                        else ->
                                                            context.getString(if (isMoveOperation) R.string.move_failed else R.string.copy_failed, entriesToMove.size)
                                                    }
                                                    Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                                                    if (result.hasSuccess) {
                                                        selectedIds = emptySet()
                                                    }
                                                }
                                            }
                                            .padding(vertical = 12.dp, horizontal = 8.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            imageVector = Icons.Outlined.Folder,
                                            contentDescription = stringResource(R.string.album_folder_desc),
                                            tint = colorScheme.onSurfaceVariant,
                                            modifier = Modifier.size(24.dp)
                                        )
                                        Spacer(modifier = Modifier.width(16.dp))
                                        Column {
                                            Text(
                                                album.name,
                                                style = MaterialTheme.typography.bodyLarge
                                            )
                                            Text(
                                                stringResource(R.string.item_count, album.itemCount),
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = colorScheme.onSurfaceVariant
                                            )
                                        }
                                    }
                                }
                            }
                        },
                        confirmButton = {},
                        dismissButton = {
                            TextButton(onClick = { showMoveToAlbumDialog = false }) {
                                Text("Cancel")
                            }
                        }
                    )
                }
            }
            
            if (showDeleteConfirmDialog) {
                DeleteConfirmationDialog(
                    itemCount = pendingDeleteEntries.size,
                    isPermanent = isPermanentDelete,
                    onConfirm = { bypassTrash ->
                        val uris = pendingDeleteEntries.map { it.uri }
                        if (isPermanentDelete || bypassTrash) {
                            photosViewModel.deleteMediaBulk(uris)
                        } else {
                            photosViewModel.moveToTrashBulk(uris)
                        }
                        selectedIds = emptySet()
                    },
                    onDismiss = {
                        showDeleteConfirmDialog = false
                        pendingDeleteEntries = emptyList()
                    }
                )
            }

            // Selection Bottom Capsule Bar
            if (selectedIds.isNotEmpty()) {
                HorizontalFloatingToolbar(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .windowInsetsPadding(WindowInsets.navigationBars)
                        .padding(bottom = 16.dp),
                    expanded = true,
                    colors = FloatingToolbarDefaults.standardFloatingToolbarColors(),
                    content = {
                        // 1. Lock/Unlock
                        val isVault = currentScreen == Screen.LockedFolder
                        Surface(
                            onClick = {
                                if (isVault) {
                                    selectedEntries.forEach { photosViewModel.restoreFromVault(it.contentId) }
                                } else {
                                    selectedEntries.forEach { photosViewModel.moveToVault(it) }
                                }
                                selectedIds = emptySet()
                            },
                            shape = FloatingToolbarDefaults.ContainerShape,
                            color = colorScheme.surface,
                            contentColor = colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = if (isVault) Icons.Outlined.LockOpen else Icons.Outlined.Lock, 
                                    contentDescription = if (isVault) stringResource(R.string.unlock) else stringResource(R.string.lock), 
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }

                        // 2. Share
                        val shareMediaTitle = stringResource(R.string.share_media)
                        Surface(
                            onClick = {
                                val uris = selectedEntries.map { 
                                    FileProvider.getUriForFile(context, "com.pixel.gallery.fileprovider", java.io.File(it.path))
                                }
                                val intent = android.content.Intent(android.content.Intent.ACTION_SEND_MULTIPLE).apply {
                                    type = "*/*"
                                    putParcelableArrayListExtra(android.content.Intent.EXTRA_STREAM, ArrayList(uris))
                                    addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                context.startActivity(android.content.Intent.createChooser(intent, shareMediaTitle))
                            },
                            shape = FloatingToolbarDefaults.ContainerShape,
                            color = colorScheme.surface,
                            contentColor = colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.Share, contentDescription = stringResource(R.string.share), modifier = Modifier.size(24.dp))
                            }
                        }

                        // 3. Delete
                        Surface(
                            onClick = {
                                if (currentScreen == Screen.Trash) {
                                    if (confirmDelete) {
                                        pendingDeleteEntries = selectedEntries
                                        isPermanentDelete = true
                                        showDeleteConfirmDialog = true
                                    } else {
                                        photosViewModel.deleteMediaBulk(selectedEntries.map { it.uri })
                                        selectedIds = emptySet()
                                    }
                                } else {
                                    if (confirmTrash) {
                                        pendingDeleteEntries = selectedEntries
                                        isPermanentDelete = false
                                        showDeleteConfirmDialog = true
                                    } else {
                                        photosViewModel.moveToTrashBulk(selectedEntries.map { it.uri })
                                        selectedIds = emptySet()
                                    }
                                }
                            },
                            shape = FloatingToolbarDefaults.ContainerShape,
                            color = colorScheme.surface,
                            contentColor = colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.Delete, contentDescription = stringResource(R.string.delete), modifier = Modifier.size(24.dp))
                            }
                        }

                        // 4. More
                        var showSelectionMoreMenu by remember { mutableStateOf(false) }
                        Box {
                            Surface(
                                onClick = { showSelectionMoreMenu = true },
                                shape = FloatingToolbarDefaults.ContainerShape,
                                color = colorScheme.surface,
                                contentColor = colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 4.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Default.MoreVert, contentDescription = stringResource(R.string.more), modifier = Modifier.size(24.dp))
                                }
                            }
                            DropdownMenu(
                                expanded = showSelectionMoreMenu,
                                onDismissRequest = { showSelectionMoreMenu = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text(stringResource(R.string.copy_to_folder)) },
                                    onClick = {
                                        showSelectionMoreMenu = false
                                        isMoveOperation = false
                                        showMoveToAlbumDialog = true
                                    },
                                    leadingIcon = { Icon(Icons.Outlined.ContentCopy, contentDescription = null) }
                                )
                                DropdownMenuItem(
                                    text = { Text(stringResource(R.string.move_to_folder)) },
                                    onClick = {
                                        showSelectionMoreMenu = false
                                        isMoveOperation = true
                                        showMoveToAlbumDialog = true
                                    },
                                    leadingIcon = { Icon(Icons.Outlined.Folder, contentDescription = null) }
                                )
                            }
                        }
                    }
                )
            }

            // Album Selection Bottom Capsule Bar
            val currentSelectedAlbums = selectedAlbumsForActions
            if (currentSelectedAlbums.isNotEmpty()) {
                val albumEntries = remember(currentSelectedAlbums, allPhotos) {
                    val names = currentSelectedAlbums.map { it.name }.toSet()
                    allPhotos.filter {
                        val parentName = java.io.File(it.path).parentFile?.name
                        parentName in names
                    }
                }
                HorizontalFloatingToolbar(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .windowInsetsPadding(WindowInsets.navigationBars)
                        .padding(bottom = 16.dp),
                    expanded = true,
                    colors = FloatingToolbarDefaults.standardFloatingToolbarColors(),
                    content = {
                        // 1. Hide Album
                        Surface(
                            onClick = {
                                currentSelectedAlbums.forEach { photosViewModel.addHiddenFolder(it.path) }
                                selectedAlbumsForActions = emptySet()
                            },
                            shape = FloatingToolbarDefaults.ContainerShape,
                            color = colorScheme.surface,
                            contentColor = colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Outlined.VisibilityOff, contentDescription = stringResource(R.string.hide_desc), modifier = Modifier.size(24.dp))
                            }
                        }

                        // 2. Exclude Album
                        Surface(
                            onClick = {
                                currentSelectedAlbums.forEach { photosViewModel.addExcludedFolder(it.path) }
                                selectedAlbumsForActions = emptySet()
                            },
                            shape = FloatingToolbarDefaults.ContainerShape,
                            color = colorScheme.surface,
                            contentColor = colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Outlined.FolderOff, contentDescription = stringResource(R.string.exclude_desc), modifier = Modifier.size(24.dp))
                            }
                        }

                        // 3. Delete Album
                        Surface(
                            onClick = {
                                pendingDeleteEntries = albumEntries
                                isPermanentDelete = false
                                showDeleteConfirmDialog = true
                            },
                            shape = FloatingToolbarDefaults.ContainerShape,
                            color = colorScheme.surface,
                            contentColor = colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.Delete, contentDescription = stringResource(R.string.delete), modifier = Modifier.size(24.dp))
                            }
                        }

                        // 4. More dropdown
                        var showAlbumMoreMenu by remember { mutableStateOf(false) }
                        Box {
                            Surface(
                                onClick = { showAlbumMoreMenu = true },
                                shape = FloatingToolbarDefaults.ContainerShape,
                                color = colorScheme.surface,
                                contentColor = colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 4.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Default.MoreVert, contentDescription = stringResource(R.string.more), modifier = Modifier.size(24.dp))
                                }
                            }
                            DropdownMenu(
                                expanded = showAlbumMoreMenu,
                                onDismissRequest = { showAlbumMoreMenu = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text(stringResource(R.string.copy_to_folder)) },
                                    onClick = {
                                        showAlbumMoreMenu = false
                                        isMoveOperation = false
                                        selectedIds = albumEntries.map { it.contentId }.toSet()
                                        showMoveToAlbumDialog = true
                                    },
                                    leadingIcon = { Icon(Icons.Outlined.ContentCopy, contentDescription = null) }
                                )
                                DropdownMenuItem(
                                    text = { Text(stringResource(R.string.move_to_folder)) },
                                    onClick = {
                                        showAlbumMoreMenu = false
                                        isMoveOperation = true
                                        selectedIds = albumEntries.map { it.contentId }.toSet()
                                        showMoveToAlbumDialog = true
                                    },
                                    leadingIcon = { Icon(Icons.Outlined.Folder, contentDescription = null) }
                                )
                            }
                        }
                    }
                )
            }

            // Post-Folder Creation photo picker
            if (showAddPhotosToNewAlbumDialog) {
                AddPhotosToNewAlbumDialog(
                    albumName = newAlbumCreatedName,
                    allPhotos = allPhotos,
                    onDismiss = {
                        showAddPhotosToNewAlbumDialog = false
                        newAlbumCreatedName = ""
                    },
                    onConfirm = { selectedList, isMove ->
                        showAddPhotosToNewAlbumDialog = false
                        photosViewModel.copyOrMoveMedia(selectedList, newAlbumCreatedName, isMove = isMove) { result ->
                            val operationPastTense = if (isMove) "Moved" else "Copied"
                            val message = if (result.hasSuccess) {
                                "$operationPastTense ${result.succeeded} items to '$newAlbumCreatedName'"
                            } else {
                                "Failed to copy/move items"
                            }
                            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                        }
                        newAlbumCreatedName = ""
                    }
                )
            }
        }
    }
}

@OptIn(com.bumptech.glide.integration.compose.ExperimentalGlideComposeApi::class, ExperimentalMaterial3Api::class)
@Composable
fun AddPhotosToNewAlbumDialog(
    albumName: String,
    allPhotos: List<com.pixel.gallery.data.local.entity.MediaEntry>,
    onDismiss: () -> Unit,
    onConfirm: (List<com.pixel.gallery.data.local.entity.MediaEntry>, Boolean) -> Unit
) {
    var selectedItems by remember { mutableStateOf(setOf<com.pixel.gallery.data.local.entity.MediaEntry>()) }
    androidx.compose.ui.window.Dialog(
        onDismissRequest = onDismiss,
        properties = androidx.compose.ui.window.DialogProperties(
            usePlatformDefaultWidth = false
        )
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            Scaffold(
                contentWindowInsets = WindowInsets.statusBars,
                topBar = {
                    TopAppBar(
                        title = { Text(stringResource(R.string.add_photos_to_album, albumName)) },
                        navigationIcon = {
                            IconButton(onClick = onDismiss) {
                                Icon(Icons.Default.Close, contentDescription = stringResource(R.string.cancel))
                            }
                        },
                        actions = {
                            TextButton(
                                onClick = { onConfirm(selectedItems.toList(), false) },
                                enabled = selectedItems.isNotEmpty()
                            ) {
                                Text(stringResource(R.string.copy_action))
                            }
                            TextButton(
                                onClick = { onConfirm(selectedItems.toList(), true) },
                                enabled = selectedItems.isNotEmpty()
                            ) {
                                Text(stringResource(R.string.move_action))
                            }
                        }
                    )
                }
            ) { innerPadding ->
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(innerPadding)
                ) {
                    if (allPhotos.isEmpty()) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(stringResource(R.string.no_photos_available))
                        }
                    } else {
                        androidx.compose.foundation.lazy.grid.LazyVerticalGrid(
                            columns = androidx.compose.foundation.lazy.grid.GridCells.Fixed(3),
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(8.dp),
                            verticalArrangement = Arrangement.spacedBy(4.dp),
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            items(allPhotos.size) { index ->
                                val item = allPhotos[index]
                                val isSelected = selectedItems.contains(item)
                                Box(
                                    modifier = Modifier
                                        .aspectRatio(1f)
                                        .clickable {
                                            selectedItems = if (isSelected) {
                                                selectedItems - item
                                            } else {
                                                selectedItems + item
                                            }
                                        }
                                ) {
                                    com.bumptech.glide.integration.compose.GlideImage(
                                        model = item.uri,
                                        contentDescription = null,
                                        contentScale = androidx.compose.ui.layout.ContentScale.Crop,
                                        modifier = Modifier.fillMaxSize()
                                    )
                                    Box(
                                        modifier = Modifier
                                            .fillMaxSize()
                                            .background(
                                                if (isSelected) Color.Black.copy(alpha = 0.3f)
                                                else Color.Transparent
                                            )
                                    )
                                    Checkbox(
                                        checked = isSelected,
                                        onCheckedChange = {
                                            selectedItems = if (isSelected) {
                                                selectedItems - item
                                            } else {
                                                selectedItems + item
                                            }
                                        },
                                        modifier = Modifier
                                            .align(Alignment.TopEnd)
                                            .padding(4.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private data class NavTab(
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)


