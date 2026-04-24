package com.pixel.gallery.ui.viewer

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.ui.theme.EmphasizedTypography
import me.saket.telephoto.zoomable.glide.ZoomableGlideImage
import me.saket.telephoto.zoomable.rememberZoomableImageState

import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import kotlinx.coroutines.flow.flowOf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ViewerScreen(
    initialId: Long,
    photos: List<MediaEntry>,
    onBack: () -> Unit,
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val initialIndex = remember(initialId, photos) {
        photos.indexOfFirst { it.contentId == initialId }.coerceAtLeast(0)
    }
    
    val pagerState = rememberPagerState(initialPage = initialIndex) { photos.size }
    var showUI by remember { mutableStateOf(true) }
    var showInfo by remember { mutableStateOf(false) }
    val context = LocalContext.current

    val currentMedia = remember(pagerState.currentPage, photos) {
        if (photos.isNotEmpty()) photos[pagerState.currentPage] else null
    }

    val isFavourite by (currentMedia?.let { viewModel.isFavourite(it.contentId) } ?: flowOf(false))
        .collectAsState(initial = false)
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
            pageSpacing = 16.dp,
            beyondViewportPageCount = 1
        ) { page ->
            val media = photos[page]
            val isVideo = media.sourceMimeType.startsWith("video/")
            
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null
                    ) {
                        showUI = !showUI
                    },
                contentAlignment = Alignment.Center
            ) {
                if (isVideo) {
                    VideoPlayer(uri = media.uri)
                } else {
                    ZoomableGlideImage(
                        model = media.uri,
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        state = rememberZoomableImageState(),
                        contentScale = ContentScale.Fit
                    )
                }
            }
        }

        // Top Overlay
        AnimatedVisibility(
            visible = showUI,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.TopCenter)
        ) {
            TopAppBar(
                title = {},
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black.copy(alpha = 0.4f),
                    navigationIconContentColor = Color.White
                )
            )
        }

        // Bottom Overlay
        AnimatedVisibility(
            visible = showUI,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            Row(
                modifier = Modifier
                    .windowInsetsPadding(WindowInsets.navigationBars)
                    .padding(bottom = 16.dp, start = 24.dp, end = 24.dp)
                    .background(Color.Black.copy(alpha = 0.6f), CircleShape)
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ViewerAction(Icons.Outlined.Share, "Share") {
                    currentMedia?.let { media ->
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = media.sourceMimeType
                            putExtra(Intent.EXTRA_STREAM, Uri.parse(media.uri))
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        context.startActivity(Intent.createChooser(intent, "Share Media"))
                    }
                }
                ViewerAction(Icons.Outlined.Edit, "Edit") {
                    currentMedia?.let { media ->
                        val intent = Intent(Intent.ACTION_EDIT).apply {
                            setDataAndType(Uri.parse(media.uri), media.sourceMimeType)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        try {
                            context.startActivity(Intent.createChooser(intent, "Edit Media"))
                        } catch (e: Exception) {
                            // Handle if no editor is found
                        }
                    }
                }
                IconButton(onClick = { 
                    currentMedia?.let { viewModel.toggleFavourite(it.contentId, isFavourite) }
                }) {
                    Icon(
                        imageVector = if (isFavourite) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                        contentDescription = "Favorite",
                        tint = if (isFavourite) Color.Red else Color.White
                    )
                }
                ViewerAction(Icons.Outlined.Info, "Info") {
                    showInfo = true
                }
                if (currentMedia?.isTrashed == true) {
                    ViewerAction(Icons.Outlined.RestoreFromTrash, "Restore") {
                        currentMedia?.let { media ->
                            viewModel.restoreMedia(media.contentId, media.uri)
                            onBack()
                        }
                    }
                } else {
                    ViewerAction(Icons.Outlined.Delete, "Delete") {
                        currentMedia?.let { media ->
                            viewModel.moveToTrash(media.contentId, media.uri, media.path)
                            onBack()
                        }
                    }
                }
            }
        }

        if (showInfo && currentMedia != null) {
            InfoBottomSheet(
                media = currentMedia,
                viewModel = viewModel,
                onDismiss = { showInfo = false }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InfoBottomSheet(
    media: MediaEntry,
    viewModel: PhotosViewModel,
    onDismiss: () -> Unit
) {
    val metadata = remember(media.path) { viewModel.getMediaMetadata(media.path) }
    val coords = remember(media.path) { viewModel.getCoordinates(media.path) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface,
        dragHandle = { BottomSheetDefaults.DragHandle() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                text = "Details",
                style = EmphasizedTypography.TitleLarge,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            // Basic Info
            InfoRow(Icons.Outlined.Image, media.path.substringAfterLast("/"), "${media.width} x ${media.height} • ${media.sizeBytes / 1024} KB")
            InfoRow(Icons.Outlined.CalendarToday, "Date Taken", metadata["Date Taken"] ?: "Unknown")

            if (metadata["Model"] != "Unknown") {
                Spacer(Modifier.height(24.dp))
                Text("Camera Info", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.height(12.dp))
                InfoRow(Icons.Outlined.CameraAlt, "${metadata["Make"]} ${metadata["Model"]}", "${metadata["Aperture"]} • ${metadata["Exposure Time"]} • ISO ${metadata["ISO"]}")
            }

            if (coords != null) {
                Spacer(Modifier.height(24.dp))
                Text("Location", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.height(12.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(150.dp)
                        .background(MaterialTheme.colorScheme.surfaceVariant, MaterialTheme.shapes.large),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Map Placeholder (${coords.first}, ${coords.second})", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

@Composable
fun InfoRow(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(24.dp))
        Spacer(Modifier.width(16.dp))
        Column {
            Text(text = title, style = MaterialTheme.typography.bodyLarge)
            Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun VideoPlayer(uri: String) {
    val context = LocalContext.current
    val exoPlayer = remember(uri) {
        ExoPlayer.Builder(context).build().apply {
            setMediaItem(MediaItem.fromUri(Uri.parse(uri)))
            repeatMode = Player.REPEAT_MODE_ONE
            prepare()
            playWhenReady = true
        }
    }

    DisposableEffect(exoPlayer) {
        onDispose {
            exoPlayer.release()
        }
    }

    AndroidView(
        factory = {
            PlayerView(it).apply {
                player = exoPlayer
                useController = true
                setBackgroundColor(android.graphics.Color.BLACK)
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}

@Composable
fun ViewerAction(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit
) {
    IconButton(onClick = onClick) {
        Icon(icon, contentDescription = label, tint = Color.White)
    }
}
