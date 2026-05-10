package com.pixel.gallery.ui.viewer

import android.app.Activity
import android.app.WallpaperManager
import android.content.Intent
import android.content.pm.ActivityInfo
import android.net.Uri
import android.os.Build
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.withContext
import me.saket.telephoto.zoomable.glide.ZoomableGlideImage
import me.saket.telephoto.zoomable.rememberZoomableImageState
import org.osmdroid.tileprovider.tilesource.XYTileSource
import java.io.File

private val MapnikHttps = XYTileSource(
    "Mapnik",
    0, 19, 256, ".png",
    arrayOf(
        "https://a.tile.openstreetmap.org/",
        "https://b.tile.openstreetmap.org/",
        "https://c.tile.openstreetmap.org/"
    ),
    "© OpenStreetMap contributors"
)

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
    var showMenu by remember { mutableStateOf(false) }
    var rotationLocked by remember { mutableStateOf(true) }
    
    val context = LocalContext.current
    val currentMedia = remember(pagerState.currentPage, photos) {
        if (photos.isNotEmpty()) photos[pagerState.currentPage] else null
    }

    // Motion Photo State
    var motionVideoFile by remember(currentMedia?.contentId) { mutableStateOf<File?>(null) }
    var isPlayingMotion by remember { mutableStateOf(false) }

    LaunchedEffect(currentMedia) {
        isPlayingMotion = false
        val file = withContext(Dispatchers.IO) {
            currentMedia?.let { viewModel.extractMotionVideo(it.path) }
        }
        val oldFile = motionVideoFile
        motionVideoFile = file
        
        // Clean up old temp file after new one is ready
        if (oldFile != null && oldFile != motionVideoFile) {
            try { 
                withContext(Dispatchers.IO) { oldFile.delete() }
            } catch (e: Exception) {}
        }
    }

    // Comprehensive cleanup on exit
    DisposableEffect(Unit) {
        onDispose {
            motionVideoFile?.delete()
        }
    }

    // Auto-hide UI timer
    LaunchedEffect(showUI, pagerState.currentPage, isPlayingMotion) {
        if (showUI && !isPlayingMotion) {
            delay(3000)
            showUI = false
        }
    }

    // Immersive Mode
    LaunchedEffect(showUI) {
        val window = (context as? Activity)?.window ?: return@LaunchedEffect
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        if (showUI) {
            controller.show(WindowInsetsCompat.Type.systemBars())
        } else {
            controller.hide(WindowInsetsCompat.Type.systemBars())
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    // Selective HDR support
    val isUltraHdr = remember(currentMedia) {
        currentMedia?.let { viewModel.isUltraHdr(it.path) } ?: false
    }

    DisposableEffect(isUltraHdr) {
        val activity = context as? Activity
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && activity != null) {
            try {
                activity.window?.colorMode = if (isUltraHdr) {
                    ActivityInfo.COLOR_MODE_HDR
                } else {
                    ActivityInfo.COLOR_MODE_DEFAULT
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        onDispose {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                try {
                    activity?.window?.colorMode = ActivityInfo.COLOR_MODE_DEFAULT
                } catch (e: Exception) {}
            }
            val window = activity?.window
            if (window != null) {
                WindowCompat.getInsetsController(window, window.decorView).show(WindowInsetsCompat.Type.systemBars())
            }
            activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
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
            beyondViewportPageCount = 0,
            userScrollEnabled = !isPlayingMotion
        ) { page ->
            val media = photos[page]
            val isVideo = media.sourceMimeType.startsWith("video/")
            
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                if (isVideo) {
                    VideoPlayer(
                        uri = media.uri, 
                        showUI = showUI, 
                        isActive = pagerState.currentPage == page,
                        onTap = { showUI = !showUI }
                    )
                } else {
                    Box(modifier = Modifier.fillMaxSize()) {
                        ZoomableGlideImage(
                            model = media.uri,
                            contentDescription = null,
                            modifier = Modifier.fillMaxSize(),
                            state = rememberZoomableImageState(),
                            contentScale = ContentScale.Fit,
                            onClick = { 
                                if (isPlayingMotion) {
                                    isPlayingMotion = false
                                } else {
                                    showUI = !showUI 
                                }
                            }
                        )
                        
                        if (isPlayingMotion && motionVideoFile != null) {
                            VideoPlayer(
                                uri = Uri.fromFile(motionVideoFile!!).toString(),
                                isMotionPhoto = true,
                                isActive = true, 
                                modifier = Modifier.fillMaxSize(),
                                onTap = { isPlayingMotion = false }
                            )
                        }
                    }
                }
            }
        }

        // Top Overlay
        AnimatedVisibility(
            visible = showUI,
            enter = fadeIn() + slideInVertically { -it },
            exit = fadeOut() + slideOutVertically { -it },
            modifier = Modifier.align(Alignment.TopCenter)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Black.copy(alpha = 0.6f), Color.Transparent)
                        )
                    )
                    .windowInsetsPadding(WindowInsets.statusBars)
            ) {
                TopAppBar(
                    title = {},
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
                        }
                    },
                    actions = {
                        if (motionVideoFile != null) {
                            IconButton(onClick = { isPlayingMotion = !isPlayingMotion }) {
                                Icon(
                                    imageVector = if (isPlayingMotion) Icons.Default.MotionPhotosPause else Icons.Default.MotionPhotosOn,
                                    contentDescription = "Motion Photo",
                                    tint = Color.White
                                )
                            }
                        }
                        IconButton(onClick = { 
                            rotationLocked = !rotationLocked
                            val activity = context as? Activity
                            activity?.requestedOrientation = if (rotationLocked) {
                                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                            } else {
                                ActivityInfo.SCREEN_ORIENTATION_SENSOR
                            }
                        }) {
                            Icon(
                                imageVector = if (rotationLocked) Icons.Outlined.ScreenLockRotation else Icons.Outlined.ScreenRotation,
                                contentDescription = "Auto-Rotate",
                                tint = Color.White
                            )
                        }
                        IconButton(onClick = { showMenu = true }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "More", tint = Color.White)
                        }
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Set as Wallpaper") },
                                onClick = {
                                    showMenu = false
                                    currentMedia?.let { media ->
                                        val intent = WallpaperManager.getInstance(context).getCropAndSetWallpaperIntent(Uri.parse(media.uri))
                                        context.startActivity(intent)
                                    }
                                },
                                leadingIcon = { Icon(Icons.Outlined.Wallpaper, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Move to locked folder") },
                                onClick = {
                                    showMenu = false
                                    currentMedia?.let { media ->
                                        viewModel.moveToVault(media)
                                        onBack()
                                    }
                                },
                                leadingIcon = { Icon(Icons.Outlined.Lock, contentDescription = null) }
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = Color.Transparent,
                        navigationIconContentColor = Color.White
                    )
                )
            }
        }

        // Bottom Overlay
        AnimatedVisibility(
            visible = showUI,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it },
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Transparent, Color.Black.copy(alpha = 0.6f))
                        )
                    )
                    .windowInsetsPadding(WindowInsets.navigationBars)
                    .padding(bottom = 16.dp, top = 24.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    ViewerAction(Icons.Outlined.Share, "Share") {
                        currentMedia?.let { media ->
                            val uri = FileProvider.getUriForFile(context, "com.pixel.gallery.fileprovider", File(media.path))
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = media.sourceMimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
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
                            } catch (e: Exception) { }
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
                        .height(200.dp)
                        .clip(MaterialTheme.shapes.large)
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    val context = LocalContext.current
                    AndroidView(
                        factory = { ctx ->
                            org.osmdroid.views.MapView(ctx).apply {
                                setTileSource(MapnikHttps)
                                setMultiTouchControls(true)
                                zoomController.setVisibility(org.osmdroid.views.CustomZoomButtonsController.Visibility.NEVER)
                                controller.setZoom(15.0)
                                val point = org.osmdroid.util.GeoPoint(coords.first, coords.second)
                                controller.setCenter(point)
                                
                                val marker = org.osmdroid.views.overlay.Marker(this)
                                marker.position = point
                                marker.setAnchor(org.osmdroid.views.overlay.Marker.ANCHOR_CENTER, org.osmdroid.views.overlay.Marker.ANCHOR_BOTTOM)
                                overlays.add(marker)
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    )
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
fun VideoPlayer(
    uri: String, 
    modifier: Modifier = Modifier,
    isMotionPhoto: Boolean = false,
    isActive: Boolean = true,
    showUI: Boolean = true,
    onTap: () -> Unit = {}
) {
    val context = LocalContext.current
    var exoPlayer by remember { mutableStateOf<ExoPlayer?>(null) }

    DisposableEffect(isActive, uri) {
        val player = if (isActive) {
            ExoPlayer.Builder(context).build().apply {
                setMediaItem(MediaItem.fromUri(Uri.parse(uri)))
                repeatMode = if (isMotionPhoto) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
                prepare()
                playWhenReady = true
            }
        } else null
        
        exoPlayer = player
        
        onDispose {
            exoPlayer = null
            player?.stop()
            player?.release()
        }
    }

    Box(
        modifier = modifier.clickable(
            interactionSource = remember { MutableInteractionSource() },
            indication = null,
            onClick = onTap
        )
    ) {
        if (exoPlayer != null) {
            AndroidView(
                factory = { ctx ->
                    PlayerView(ctx).apply {
                        player = exoPlayer
                        useController = false
                        setBackgroundColor(android.graphics.Color.BLACK)
                    }
                },
                update = { view ->
                    view.player = exoPlayer
                },
                onRelease = { view ->
                    view.player = null
                },
                modifier = Modifier.fillMaxSize()
            )
            
            if (!isMotionPhoto) {
                VideoControls(
                    player = exoPlayer!!,
                    isVisible = showUI,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}

@Composable
fun VideoControls(
    player: Player,
    isVisible: Boolean,
    modifier: Modifier = Modifier
) {
    var isPlaying by remember { mutableStateOf(false) }
    var currentPosition by remember { mutableLongStateOf(0L) }
    var duration by remember { mutableLongStateOf(0L) }

    LaunchedEffect(player) {
        while (true) {
            try {
                isPlaying = player.isPlaying
                currentPosition = player.currentPosition
                duration = player.duration.coerceAtLeast(0L)
            } catch (e: Exception) {
                break
            }
            delay(500)
        }
    }

    AnimatedVisibility(
        visible = isVisible,
        enter = fadeIn(),
        exit = fadeOut(),
        modifier = modifier
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            IconButton(
                onClick = { 
                    try {
                        if (player.isPlaying) player.pause() else player.play()
                    } catch (e: Exception) {}
                },
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(64.dp)
                    .background(Color.Black.copy(alpha = 0.4f), CircleShape)
            ) {
                Icon(
                    imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                    contentDescription = if (isPlaying) "Pause" else "Play",
                    tint = Color.White,
                    modifier = Modifier.size(40.dp)
                )
            }

            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 96.dp)
                    .padding(horizontal = 24.dp)
                    .fillMaxWidth()
            ) {
                Slider(
                    value = currentPosition.toFloat(),
                    onValueChange = { 
                        try {
                            player.seekTo(it.toLong()) 
                        } catch (e: Exception) {}
                    },
                    valueRange = 0f..duration.toFloat().coerceAtLeast(1f),
                    colors = SliderDefaults.colors(
                        thumbColor = Color.White,
                        activeTrackColor = Color.White,
                        inactiveTrackColor = Color.White.copy(alpha = 0.3f)
                    )
                )
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = formatTime(currentPosition),
                        style = MaterialTheme.typography.labelMedium,
                        color = Color.White
                    )
                    Text(
                        text = formatTime(duration),
                        style = MaterialTheme.typography.labelMedium,
                        color = Color.White
                    )
                }
            }
        }
    }
}

private fun formatTime(millis: Long): String {
    val seconds = (millis / 1000) % 60
    val minutes = (millis / (1000 * 60)) % 60
    val hours = millis / (1000 * 60 * 60)
    return if (hours > 0) {
        String.format("%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format("%02d:%02d", minutes, seconds)
    }
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
