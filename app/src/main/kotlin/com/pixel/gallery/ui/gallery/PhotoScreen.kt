package com.pixel.gallery.ui.gallery

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.Spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.FolderOff
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Photo
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.bumptech.glide.integration.compose.ExperimentalGlideComposeApi
import com.bumptech.glide.integration.compose.GlideImage
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel.GridItem
import java.io.File

sealed class AlbumSource {
    object Recents : AlbumSource()
    object Favourites : AlbumSource()
    data class Folder(val name: String) : AlbumSource()
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalGlideComposeApi::class)
@Composable
fun PhotoScreen(
    albumName: String,
    onBack: () -> Unit,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onSelectionChange: (Set<Long>) -> Unit = {},
    onToggleSelection: (Long) -> Unit = {},
    gridState: LazyGridState = rememberLazyGridState(),
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val allPhotos by viewModel.allPhotos.collectAsState()
    val photos by viewModel.photos.collectAsState()
    val favourites by viewModel.favourites.collectAsState()
    val albums by viewModel.albums.collectAsState()
    val gridColumns by viewModel.gridColumns.collectAsState()
    val ribbonOpen by viewModel.ribbonOpen.collectAsState()

    var currentSource by remember(albumName) {
        mutableStateOf<AlbumSource>(AlbumSource.Folder(albumName))
    }

    val currentPhotos = remember(currentSource, allPhotos, photos, favourites) {
        when (val source = currentSource) {
            is AlbumSource.Recents -> photos
            is AlbumSource.Favourites -> favourites
            is AlbumSource.Folder -> {
                allPhotos.filter { 
                    val file = File(it.path)
                    file.parentFile?.name == source.name
                }
            }
        }
    }

    val currentTitle = remember(currentSource) {
        when (val source = currentSource) {
            is AlbumSource.Recents -> "Recents"
            is AlbumSource.Favourites -> "Favourites"
            is AlbumSource.Folder -> source.name
        }
    }

    val albumItems = remember(currentPhotos, gridColumns) {
        viewModel.groupMedia(currentPhotos, gridColumns)
    }

    val photoCount = remember(albumItems) {
        albumItems.count { it is GridItem.Photo }
    }

    val coverPhoto = remember(currentPhotos) {
        currentPhotos.firstOrNull()
    }

    var showMenu by remember { mutableStateOf(false) }
    val albumPath = remember(allPhotos, currentSource) {
        if (currentSource is AlbumSource.Folder) {
            val name = (currentSource as AlbumSource.Folder).name
            allPhotos.find { 
                File(it.path).parentFile?.name == name 
            }?.let { File(it.path).parent } ?: ""
        } else ""
    }

    var swipeOffsetX by remember { mutableStateOf(0f) }

    val ribbonWidth by animateDpAsState(
        targetValue = if (ribbonOpen) 80.dp else 0.dp,
        animationSpec = spring(stiffness = Spring.StiffnessLow),
        label = "RibbonWidth"
    )

    val targetColumns = if (ribbonOpen) 2 else 3

    Column(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragStart = { swipeOffsetX = 0f },
                    onDragEnd = {
                        if (swipeOffsetX > 100) {
                            viewModel.setRibbonOpen(true)
                        } else if (swipeOffsetX < -100) {
                            viewModel.setRibbonOpen(false)
                        }
                    },
                    onHorizontalDrag = { change, dragAmount ->
                        swipeOffsetX += dragAmount
                    }
                )
            }
    ) {
        // Banner / Header (Full Width)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp)
        ) {
            if (coverPhoto != null) {
                GlideImage(
                    model = coverPhoto.uri,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                )
            }

            // Dark gradient scrim
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(
                                Color.Black.copy(alpha = 0.4f),
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.6f)
                            )
                        )
                    )
            )

            // Top navigation overlay buttons (Status bar padded)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = onBack,
                    modifier = Modifier
                        .background(Color.Black.copy(alpha = 0.4f), CircleShape)
                ) {
                    Icon(
                        Icons.Default.ChevronLeft,
                        contentDescription = "Back",
                        tint = Color.White
                    )
                }

                if (currentSource is AlbumSource.Folder) {
                    Box {
                        IconButton(
                            onClick = { showMenu = true },
                            modifier = Modifier
                                .background(Color.Black.copy(alpha = 0.4f), CircleShape)
                        ) {
                            Icon(
                                Icons.Default.MoreVert,
                                contentDescription = "More",
                                tint = Color.White
                            )
                        }
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Hide Album") },
                                onClick = {
                                    showMenu = false
                                    if (albumPath.isNotEmpty()) {
                                        viewModel.addHiddenFolder(albumPath)
                                        onBack()
                                    }
                                },
                                leadingIcon = { Icon(Icons.Outlined.VisibilityOff, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Exclude Album") },
                                onClick = {
                                    showMenu = false
                                    if (albumPath.isNotEmpty()) {
                                        viewModel.addExcludedFolder(albumPath)
                                        onBack()
                                    }
                                },
                                leadingIcon = { Icon(Icons.Outlined.FolderOff, contentDescription = null) }
                            )
                        }
                    }
                }
            }

            // Album title and photo count overlayed centered
            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = currentTitle,
                    style = EmphasizedTypography.HeadlineMedium,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "$photoCount items",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White.copy(alpha = 0.8f),
                    textAlign = TextAlign.Center
                )
            }
        }

        // Side-by-side Layout below the banner
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        ) {
            if (ribbonWidth > 0.dp) {
                // Album Ribbon Sidebar (Starts below the banner)
                Surface(
                    modifier = Modifier
                        .width(ribbonWidth)
                        .fillMaxHeight(),
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    tonalElevation = 2.dp
                ) {
                    Box(modifier = Modifier.width(80.dp)) {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(vertical = 16.dp, horizontal = 4.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            // Recents Tab
                            item {
                                RibbonItem(
                                    coverUri = photos.firstOrNull()?.uri,
                                    label = "Recents",
                                    count = photos.size,
                                    isSelected = currentSource is AlbumSource.Recents,
                                    onClick = { currentSource = AlbumSource.Recents }
                                )
                            }

                            // Favorites Tab
                            item {
                                RibbonItem(
                                    coverUri = null,
                                    label = "Favourites",
                                    count = favourites.size,
                                    isSelected = currentSource is AlbumSource.Favourites,
                                    onClick = { currentSource = AlbumSource.Favourites }
                                )
                            }

                            // Album Folders list
                            items(albums, key = { it.path }) { album ->
                                RibbonItem(
                                    coverUri = album.coverUri,
                                    label = album.name,
                                    count = album.itemCount,
                                    isSelected = currentSource is AlbumSource.Folder && (currentSource as AlbumSource.Folder).name == album.name,
                                    onClick = { currentSource = AlbumSource.Folder(album.name) }
                                )
                            }
                        }
                    }
                }
                Box(
                    modifier = Modifier
                        .width(1.dp)
                        .fillMaxHeight()
                        .background(MaterialTheme.colorScheme.outlineVariant)
                )
            }

            // Photo Grid (occupies remaining weight)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
            ) {
                PhotosScreen(
                    items = albumItems,
                    onNavigateToViewer = onNavigateToViewer,
                    selectedIds = selectedIds,
                    onSelectionChange = onSelectionChange,
                    onToggleSelection = onToggleSelection,
                    columns = targetColumns,
                    onColumnsChange = { viewModel.setGridColumns(it) },
                    state = gridState
                )
            }
        }
    }
}

@OptIn(ExperimentalGlideComposeApi::class)
@Composable
fun RibbonItem(
    coverUri: String?,
    label: String,
    count: Int,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(
                    if (isSelected) MaterialTheme.colorScheme.primaryContainer 
                    else MaterialTheme.colorScheme.surfaceVariant
                )
                .run {
                    if (isSelected) {
                        border(
                            width = 2.dp,
                            color = MaterialTheme.colorScheme.primary,
                            shape = RoundedCornerShape(16.dp)
                        )
                    } else this
                },
            contentAlignment = Alignment.Center
        ) {
            if (coverUri != null) {
                GlideImage(
                    model = coverUri,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Icon(
                    imageVector = Icons.Outlined.FavoriteBorder,
                    contentDescription = null,
                    tint = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(28.dp)
                )
            }
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        Text(
            text = "$count",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}
