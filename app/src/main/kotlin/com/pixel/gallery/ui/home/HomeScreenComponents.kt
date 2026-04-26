package com.pixel.gallery.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.FolderOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.material.icons.filled.PlayArrow
import com.bumptech.glide.integration.compose.ExperimentalGlideComposeApi
import com.bumptech.glide.integration.compose.GlideImage
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.model.Album
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.theme.ExpressiveShapes
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.ui.graphics.graphicsLayer
import com.pixel.gallery.ui.utils.photoGridDragSelect
import com.pixel.gallery.ui.utils.pinchToZoomColumns
import com.pixel.gallery.ui.viewmodel.PhotosViewModel.GridItem

@OptIn(ExperimentalGlideComposeApi::class)
@Composable
fun PhotosScreen(
    items: List<GridItem>,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onSelectionChange: (Set<Long>) -> Unit = {},
    onToggleSelection: (Long) -> Unit = {},
    columns: Int = 3,
    onColumnsChange: (Int) -> Unit = {},
    bottomPadding: Dp = 0.dp,
    state: LazyGridState = rememberLazyGridState()
) {
    Box(modifier = Modifier.fillMaxSize()) {
        LazyVerticalGrid(
            columns = GridCells.Fixed(columns),
            state = state,
            modifier = Modifier
                .fillMaxSize()
                .photoGridDragSelect(
                    gridState = state,
                    items = items,
                    selectedIds = selectedIds,
                    onSelectionChange = onSelectionChange,
                    isPhoto = { index -> items[index] is GridItem.Photo },
                    getPhotoId = { index -> (items[index] as GridItem.Photo).entry.contentId }
                )
                .pinchToZoomColumns(
                    currentColumns = columns,
                    onColumnsChange = onColumnsChange,
                    minColumns = 2,
                    maxColumns = 6
                ),
            contentPadding = PaddingValues(
                start = 4.dp,
                top = 4.dp,
                end = 4.dp,
                bottom = 80.dp + bottomPadding
            ),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            items(
                count = items.size,
                key = { index ->
                    when (val item = items[index]) {
                        is GridItem.Header -> "header_${item.title}_${item.timestamp}"
                        is GridItem.Photo -> item.entry.contentId
                    }
                },
                span = { index ->
                    when (items[index]) {
                        is GridItem.Header -> androidx.compose.foundation.lazy.grid.GridItemSpan(columns)
                        is GridItem.Photo -> androidx.compose.foundation.lazy.grid.GridItemSpan(1)
                    }
                }
            ) { index ->
                when (val item = items[index]) {
                    is GridItem.Header -> {
                        val headerPhotos = remember(item, items) {
                            val photos = mutableListOf<Long>()
                            for (i in index + 1 until items.size) {
                                val nextItem = items[i]
                                if (nextItem is GridItem.Header) break
                                if (nextItem is GridItem.Photo) photos.add(nextItem.entry.contentId)
                            }
                            photos
                        }
                        val isHeaderSelected = headerPhotos.isNotEmpty() && headerPhotos.all { selectedIds.contains(it) }
                        
                        DateHeader(
                            title = item.title,
                            isSelectionMode = selectedIds.isNotEmpty(),
                            isSelected = isHeaderSelected,
                            onToggleSelection = {
                                if (isHeaderSelected) {
                                    onSelectionChange(selectedIds - headerPhotos.toSet())
                                } else {
                                    onSelectionChange(selectedIds + headerPhotos.toSet())
                                }
                            }
                        )
                    }
                    is GridItem.Photo -> {
                        val media = item.entry
                        val isSelected = selectedIds.contains(media.contentId)
                        
                        PhotoTile(
                            media = media,
                            isSelected = isSelected,
                            isSelectionMode = selectedIds.isNotEmpty(),
                            onClick = {
                                if (selectedIds.isNotEmpty()) {
                                    onToggleSelection(media.contentId)
                                } else {
                                    onNavigateToViewer(media.contentId)
                                }
                            },
                            onLongClick = {
                                onToggleSelection(media.contentId)
                            }
                        )
                    }
                }
            }
        }

        com.pixel.gallery.ui.components.VerticalScrollbar(
            gridState = state,
            modifier = Modifier
                .align(Alignment.CenterEnd)
                .padding(bottom = bottomPadding)
        )
    }
}

@OptIn(ExperimentalGlideComposeApi::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun PhotoTile(
    media: MediaEntry,
    isSelected: Boolean,
    isSelectionMode: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    val isVideo = remember(media.sourceMimeType) { media.sourceMimeType.startsWith("video/") }
    val formattedDuration = remember(media.durationMillis) {
        media.durationMillis?.let { ms ->
            val totalSeconds = ms / 1000
            val minutes = totalSeconds / 60
            val seconds = totalSeconds % 60
            val hours = minutes / 60
            if (hours > 0) {
                java.lang.String.format(java.util.Locale.getDefault(), "%d:%02d:%02d", hours, minutes % 60, seconds)
            } else {
                java.lang.String.format(java.util.Locale.getDefault(), "%d:%02d", minutes, seconds)
            }
        }
    }

    val transition = updateTransition(isSelected, label = "SelectionTransition")
    
    val scale by transition.animateFloat(
        label = "Scale",
        transitionSpec = { 
            if (targetState) {
                spring(dampingRatio = Spring.DampingRatioLowBouncy, stiffness = Spring.StiffnessLow) 
            } else {
                spring(stiffness = Spring.StiffnessLow)
            }
        }
    ) { state ->
        if (state) 0.92f else 1.0f
    }
    
    val cornerRadius by transition.animateDp(
        label = "CornerRadius",
        transitionSpec = { spring(stiffness = Spring.StiffnessLow) }
    ) { state ->
        if (state) 28.dp else 20.dp
    }
    
    val overlayAlpha by transition.animateFloat(
        label = "OverlayAlpha",
        transitionSpec = { tween(200) }
    ) { state ->
        if (state) 0.3f else 0.0f
    }

    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clip(RoundedCornerShape(cornerRadius))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongClick
            )
    ) {
        GlideImage(
            model = media.uri,
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize()
        )
        
        // Selection overlay
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.primary.copy(alpha = overlayAlpha))
        )
        
        // Selection indicators
        if (isSelectionMode) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
            ) {
                androidx.compose.animation.AnimatedVisibility(
                    visible = isSelected,
                    enter = scaleIn() + fadeIn(),
                    exit = scaleOut() + fadeOut()
                ) {
                    Icon(
                        imageVector = Icons.Filled.CheckCircle,
                        contentDescription = "Selected",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp).background(Color.White, CircleShape)
                    )
                }
                
                androidx.compose.animation.AnimatedVisibility(
                    visible = !isSelected,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .background(Color.Black.copy(alpha = 0.3f), CircleShape)
                            .padding(2.dp)
                            .background(Color.White.copy(alpha = 0.5f), CircleShape)
                    )
                }
            }
        }
        
        // Video indicators
        if (isVideo && !isSelectionMode) {
            Row(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
                    .background(Color.Black.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                if (formattedDuration != null) {
                    Text(
                        text = formattedDuration,
                        color = Color.White,
                        style = MaterialTheme.typography.labelSmall
                    )
                }
                Icon(
                    imageVector = Icons.Filled.PlayArrow,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(12.dp)
                )
            }
        }
    }
}

@Composable
fun AlbumsScreen(
    albums: List<Album>,
    bottomPadding: Dp = 0.dp,
    gridState: LazyGridState = rememberLazyGridState(),
    onNavigateToFavourites: () -> Unit,
    onNavigateToTrash: () -> Unit,
    onNavigateToAlbum: (String) -> Unit,
    onExclude: (String) -> Unit = {},
    onHide: (String) -> Unit = {}
) {
    Box(modifier = Modifier.fillMaxSize()) {
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            state = gridState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(
                start = 16.dp,
                top = 16.dp,
                end = 16.dp,
                bottom = 80.dp + bottomPadding
            ),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header Buttons: Favourites and Bin
            item(span = { androidx.compose.foundation.lazy.grid.GridItemSpan(2) }) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    AlbumHeaderButton(
                        modifier = Modifier.weight(1.0f),
                        icon = Icons.Outlined.StarOutline,
                        label = "Favourites",
                        onClick = onNavigateToFavourites
                    )
                    AlbumHeaderButton(
                        modifier = Modifier.weight(1.0f),
                        icon = Icons.Outlined.DeleteOutline,
                        label = "Recycle Bin",
                        onClick = onNavigateToTrash
                    )
                }
            }

            items(
                count = albums.size,
                key = { albums[it].name }
            ) { index ->
                AlbumCard(
                    album = albums[index],
                    onClick = { onNavigateToAlbum(albums[index].name) },
                    onExclude = { onExclude(albums[index].path) },
                    onHide = { onHide(albums[index].path) }
                )
            }
        }

        com.pixel.gallery.ui.components.VerticalScrollbar(
            gridState = gridState,
            modifier = Modifier
                .align(Alignment.CenterEnd)
                .padding(bottom = bottomPadding)
        )
    }
}

@OptIn(ExperimentalGlideComposeApi::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun AlbumCard(
    album: Album,
    onClick: () -> Unit,
    onExclude: () -> Unit,
    onHide: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier.combinedClickable(
            onClick = onClick,
            onLongClick = { showMenu = true }
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .background(
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    shape = ExpressiveShapes.ExtraLargeIncreased
                )
                .clip(ExpressiveShapes.ExtraLargeIncreased),
            contentAlignment = Alignment.Center
        ) {
            GlideImage(
                model = album.coverUri,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        }
        Spacer(Modifier.height(12.dp))
        Text(
            text = album.name,
            style = EmphasizedTypography.TitleLarge, // M3E Emphasized
            modifier = Modifier.padding(start = 4.dp)
        )
        Text(
            text = "${album.itemCount} items",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(start = 4.dp, top = 2.dp)
        )

        DropdownMenu(
            expanded = showMenu,
            onDismissRequest = { showMenu = false }
        ) {
            DropdownMenuItem(
                text = { Text("Hide Album") },
                onClick = {
                    showMenu = false
                    onHide()
                },
                leadingIcon = { Icon(Icons.Outlined.VisibilityOff, contentDescription = null) }
            )
            DropdownMenuItem(
                text = { Text("Exclude Album") },
                onClick = {
                    showMenu = false
                    onExclude()
                },
                leadingIcon = { Icon(Icons.Outlined.FolderOff, contentDescription = null) }
            )
        }
    }
}

@Composable
fun PhotoTilePlaceholder(index: Int) {
    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .clip(ExpressiveShapes.LargeIncreased)
            .background(MaterialTheme.colorScheme.surfaceVariant)
    )
}

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun AlbumHeaderButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        onClick = onClick,
        modifier = modifier,
        shape = ExpressiveShapes.LargeIncreased,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
            contentColor = MaterialTheme.colorScheme.primary
        )
    ) {
        Row(
            modifier = Modifier
                .padding(vertical = 16.dp, horizontal = 12.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(24.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                text = label,
                style = EmphasizedTypography.LabelLarge
            )
        }
    }
}

@Composable
fun DateHeader(
    title: String,
    isSelectionMode: Boolean,
    isSelected: Boolean,
    onToggleSelection: () -> Unit
) {
    Row(
        modifier = Modifier
            .padding(start = 8.dp, top = 16.dp, bottom = 8.dp, end = 16.dp)
            .fillMaxWidth()
            .clickable(enabled = isSelectionMode, onClick = onToggleSelection),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = EmphasizedTypography.LabelLarge,
            color = MaterialTheme.colorScheme.primary
        )
        if (isSelectionMode) {
            Icon(
                imageVector = if (isSelected) Icons.Filled.CheckCircle else Icons.Outlined.RadioButtonUnchecked,
                contentDescription = "Select Group",
                tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}
