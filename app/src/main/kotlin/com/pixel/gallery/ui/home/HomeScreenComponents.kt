package com.pixel.gallery.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.theme.ExpressiveShapes
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.draw.clip
import com.bumptech.glide.integration.compose.ExperimentalGlideComposeApi
import com.bumptech.glide.integration.compose.GlideImage
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.model.Album

import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.runtime.*

@OptIn(ExperimentalGlideComposeApi::class)
@Composable
fun PhotosScreen(
    photos: List<MediaEntry>,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onToggleSelection: (Long) -> Unit = {},
    columns: Int = 3,
    bottomPadding: Dp = 0.dp
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(columns),
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = 4.dp,
            top = 4.dp,
            end = 4.dp,
            bottom = 4.dp + bottomPadding
        ),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        items(
            count = photos.size,
            key = { photos[it].contentId }
        ) { index ->
            val media = photos[index]
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

@OptIn(ExperimentalGlideComposeApi::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun PhotoTile(
    media: MediaEntry,
    isSelected: Boolean,
    isSelectionMode: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .clip(ExpressiveShapes.LargeIncreased)
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
            modifier = Modifier
                .fillMaxSize()
                .then(
                    if (isSelected) Modifier.padding(12.dp).clip(MaterialTheme.shapes.medium) else Modifier
                )
        )

        if (isSelected) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
            )
            Icon(
                imageVector = Icons.Filled.CheckCircle,
                contentDescription = "Selected",
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
            )
        } else if (isSelectionMode) {
            // Outline for unselected items in selection mode
            Box(
                modifier = Modifier
                    .padding(8.dp)
                    .size(24.dp)
                    .align(Alignment.TopEnd)
                    .background(Color.Black.copy(alpha = 0.3f), CircleShape)
                    .padding(2.dp)
                    .background(Color.White.copy(alpha = 0.5f), CircleShape)
            )
        }
    }
}

@Composable
fun AlbumsScreen(
    albums: List<Album>,
    bottomPadding: Dp = 0.dp,
    onNavigateToFavourites: () -> Unit,
    onNavigateToTrash: () -> Unit,
    onNavigateToAlbum: (String) -> Unit
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = 16.dp,
            top = 16.dp,
            end = 16.dp,
            bottom = 16.dp + bottomPadding
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
                onClick = { onNavigateToAlbum(albums[index].name) }
            )
        }
    }
}

@OptIn(ExperimentalGlideComposeApi::class)
@Composable
fun AlbumCard(
    album: Album,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier.clickable { onClick() }
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
