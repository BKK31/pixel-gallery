package com.pixel.gallery.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
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
import androidx.compose.runtime.saveable.rememberSaveable
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
    @Parcelize data class Photo(val albumName: String) : Screen()

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
                                if (confirmDelete) {
                                    pendingDeleteEntries = selectedEntries
                                    isPermanentDelete = true
                                    showDeleteConfirmDialog = true
                                } else {
                                    photosViewModel.deleteMediaBulk(selectedEntries.map { it.uri })
                                    selectedIds = emptySet()
                                }
                            }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete permanently")
                            }
                        } else if (currentScreen == Screen.LockedFolder) {
                            IconButton(onClick = { 
                                selectedEntries.forEach { photosViewModel.restoreFromVault(it.contentId) }
                                selectedIds = emptySet()
                            }) {
                                Icon(Icons.Outlined.LockOpen, contentDescription = "Unlock")
                            }
                        } else {
                            IconButton(onClick = { 
                                val uris = selectedEntries.map { 
                                    FileProvider.getUriForFile(context, "com.pixel.gallery.fileprovider", java.io.File(it.path))
                                }
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
                                if (confirmTrash) {
                                    pendingDeleteEntries = selectedEntries
                                    isPermanentDelete = false
                                    showDeleteConfirmDialog = true
                                } else {
                                    photosViewModel.moveToTrashBulk(selectedEntries.map { it.uri })
                                    selectedIds = emptySet()
                                }
                            }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete")
                            }

                            var showSelectionMenu by remember { mutableStateOf(false) }
                            Box {
                                IconButton(onClick = { showSelectionMenu = true }) {
                                    Icon(Icons.Default.MoreVert, contentDescription = "More options")
                                }
                                DropdownMenu(
                                    expanded = showSelectionMenu,
                                    onDismissRequest = { showSelectionMenu = false }
                                ) {
                                    DropdownMenuItem(
                                        text = { Text("Copy to folder") },
                                        onClick = {
                                            showSelectionMenu = false
                                            isMoveOperation = false
                                            showMoveToAlbumDialog = true
                                        },
                                        leadingIcon = { Icon(Icons.Outlined.ContentCopy, contentDescription = null) }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("Move to folder") },
                                        onClick = {
                                            showSelectionMenu = false
                                            isMoveOperation = true
                                            showMoveToAlbumDialog = true
                                        },
                                        leadingIcon = { Icon(Icons.Outlined.Folder, contentDescription = null) }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("Lock") },
                                        onClick = {
                                            showSelectionMenu = false
                                            selectedEntries.forEach { photosViewModel.moveToVault(it) }
                                            selectedIds = emptySet()
                                        },
                                        leadingIcon = { Icon(Icons.Outlined.Lock, contentDescription = null) }
                                    )
                                }
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
                                onNavigateToAlbum = { name -> navigationStack = navigationStack + Screen.Photo(name) },
                                onExclude = { path -> photosViewModel.addExcludedFolder(path) },
                                onHide = { path -> photosViewModel.addHiddenFolder(path) }
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
                        onNavigateToViewer = { id -> 
                            navigationStack = navigationStack + Screen.Viewer(id, Screen.ViewerSource.Album, albumName) 
                        },
                        selectedIds = selectedIds,
                        onSelectionChange = updateSelection,
                        onToggleSelection = toggleSelection,
                        gridState = albumPhotoGridState
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
                            val isSelected = homePagerState.currentPage == index
                            
                            // Using a pill-shaped item that shows a label when selected
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

            // Dialogs for album copy and move operations
            if (showMoveToAlbumDialog) {
                var showNewAlbumNameInput by remember { mutableStateOf(false) }
                var newAlbumNameInput by remember { mutableStateOf("") }
                
                val operationName = if (isMoveOperation) "Move" else "Copy"
                val operationPastTense = if (isMoveOperation) "Moved" else "Copied"

                if (showNewAlbumNameInput) {
                    AlertDialog(
                        onDismissRequest = { showNewAlbumNameInput = false },
                        title = { Text("Create new album") },
                        text = {
                            OutlinedTextField(
                                value = newAlbumNameInput,
                                onValueChange = { newAlbumNameInput = it },
                                label = { Text("Album name") },
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
                                                    "$operationPastTense ${result.succeeded} items to '$name', failed ${result.failed}"
                                                result.hasSuccess ->
                                                    "$operationPastTense ${result.succeeded} items to '$name'"
                                                result.skipped > 0 && !result.hasFailure ->
                                                    "No items ${operationPastTense.lowercase()}"
                                                else ->
                                                    "Failed to ${operationName.lowercase()} ${entriesToMove.size} items"
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
                                Text("Cancel")
                            }
                        }
                    )
                } else {
                    AlertDialog(
                        onDismissRequest = { showMoveToAlbumDialog = false },
                        title = { Text("$operationName to Album") },
                        text = {
                            LazyColumn(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                item {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable { showNewAlbumNameInput = true }
                                            .padding(vertical = 12.dp, horizontal = 8.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            imageVector = Icons.Outlined.CreateNewFolder,
                                            contentDescription = "New Album",
                                            tint = colorScheme.primary,
                                            modifier = Modifier.size(24.dp)
                                        )
                                        Spacer(modifier = Modifier.width(16.dp))
                                        Text(
                                            "New Album...",
                                            style = MaterialTheme.typography.bodyLarge,
                                            color = colorScheme.primary
                                        )
                                    }
                                }
                                
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
                                                            "$operationPastTense ${result.succeeded} items to '${album.name}', failed ${result.failed}"
                                                        result.hasSuccess ->
                                                            "$operationPastTense ${result.succeeded} items to '${album.name}'"
                                                        result.skipped > 0 && !result.hasFailure ->
                                                            "No items ${operationPastTense.lowercase()}"
                                                        else ->
                                                            "Failed to ${operationName.lowercase()} ${entriesToMove.size} items"
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
                                            contentDescription = "Album Folder",
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
                                                "${album.itemCount} items",
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
        }
    }
}

private data class NavTab(
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)
