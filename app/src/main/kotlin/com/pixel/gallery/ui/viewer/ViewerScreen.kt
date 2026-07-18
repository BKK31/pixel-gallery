package com.pixel.gallery.ui.viewer

import android.app.Activity
import android.app.WallpaperManager
import android.graphics.Bitmap
import android.content.Intent
import android.content.pm.ActivityInfo
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
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
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.FileProvider
import android.content.res.Configuration
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.hilt.navigation.compose.hiltViewModel
import com.bumptech.glide.Glide
import com.pixel.gallery.ui.components.DeleteConfirmationDialog
import com.pixel.gallery.utils.BitmapUtils
import com.pixel.gallery.utils.MimeTypes
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
import kotlinx.coroutines.launch
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
    isVault: Boolean = false,
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
    var showWallpaperSheet by remember { mutableStateOf(false) }
    var wallpaperCropMedia by remember { mutableStateOf<MediaEntry?>(null) }
    var wallpaperBusy by remember { mutableStateOf(false) }
    var wallpaperMessage by remember { mutableStateOf<String?>(null) }
    var rotationLocked by remember { mutableStateOf(true) }
    val wallpaperScope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    
    val confirmTrash by viewModel.confirmTrash.collectAsState()
    val confirmDelete by viewModel.confirmDelete.collectAsState()
    val videoMuted by viewModel.videoMuted.collectAsState()

    var showDeleteConfirmDialog by remember { mutableStateOf(false) }
    var isPermanentDelete by remember { mutableStateOf(false) }

    val context = LocalContext.current
    val currentMedia = remember(pagerState.currentPage, photos) {
        if (photos.isNotEmpty()) photos[pagerState.currentPage] else null
    }

    // Motion Photo State
    var motionVideoFile by remember(currentMedia?.contentId) { mutableStateOf<File?>(null) }
    var isPlayingMotion by remember { mutableStateOf(false) }
    val canSetWallpaper = remember(currentMedia, motionVideoFile) {
        val media = currentMedia
        media != null &&
            motionVideoFile == null &&
            MimeTypes.isImage(media.sourceMimeType) &&
            media.sourceMimeType != MimeTypes.SVG &&
            !MimeTypes.isRaw(media.sourceMimeType)
    }

    LaunchedEffect(currentMedia) {
        isPlayingMotion = false
        showMenu = false
        showWallpaperSheet = false
        wallpaperCropMedia = null
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

    LaunchedEffect(wallpaperMessage) {
        val message = wallpaperMessage ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(message)
        wallpaperMessage = null
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
                        isMuted = videoMuted,
                        onMuteChange = { viewModel.setVideoMuted(it) },
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
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Back Button (Circle Container)
                Surface(
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.9f)
                ) {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.Default.ChevronLeft,
                            contentDescription = "Back",
                            tint = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                    }
                }

                // Actions Capsule Container
                Surface(
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.9f)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        if (motionVideoFile != null) {
                            IconButton(onClick = { isPlayingMotion = !isPlayingMotion }) {
                                Icon(
                                    imageVector = if (isPlayingMotion) Icons.Default.MotionPhotosPause else Icons.Default.MotionPhotosOn,
                                    contentDescription = "Motion Photo",
                                    tint = MaterialTheme.colorScheme.onSecondaryContainer
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
                                tint = MaterialTheme.colorScheme.onSecondaryContainer
                            )
                        }
                        Box {
                            IconButton(onClick = { showMenu = true }) {
                                Icon(Icons.Default.MoreVert, contentDescription = "More", tint = MaterialTheme.colorScheme.onSecondaryContainer)
                            }
                            DropdownMenu(
                                expanded = showMenu,
                                onDismissRequest = { showMenu = false }
                            ) {
                                if (canSetWallpaper) {
                                    DropdownMenuItem(
                                        text = { Text("Set as Wallpaper") },
                                        onClick = {
                                            showMenu = false
                                            showWallpaperSheet = true
                                        },
                                        leadingIcon = { Icon(Icons.Outlined.Wallpaper, contentDescription = null) }
                                    )
                                }
                                DropdownMenuItem(
                                    text = { Text(if (isVault) "Remove from locked folder" else "Move to locked folder") },
                                    onClick = {
                                        showMenu = false
                                        currentMedia?.let { media ->
                                            if (isVault) {
                                                viewModel.restoreFromVault(media.contentId)
                                            } else {
                                                viewModel.moveToVault(media)
                                            }
                                            onBack()
                                        }
                                    },
                                    leadingIcon = { Icon(if (isVault) Icons.Outlined.LockOpen else Icons.Outlined.Lock, contentDescription = null) }
                                )
                                DropdownMenuItem(
                                    text = { Text("Open With") },
                                    onClick = {
                                        showMenu = false
                                        currentMedia?.let { media ->
                                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                                setDataAndType(Uri.parse(media.uri), media.sourceMimeType)
                                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                            }
                                            try {
                                                context.startActivity(Intent.createChooser(intent, "Open with..."))
                                            } catch (e: Exception) { }
                                        }
                                    },
                                    leadingIcon = { Icon(Icons.AutoMirrored.Outlined.OpenInNew, contentDescription = null) }
                                )
                            }
                        }
                    }
                }
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
                    .navigationBarsPadding()
                    .padding(bottom = 24.dp),
                contentAlignment = Alignment.BottomCenter
            ) {
                Surface(
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.9f),
                    modifier = Modifier.padding(horizontal = 24.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
                        horizontalArrangement = Arrangement.spacedBy(20.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // 1. Favorite
                        IconButton(onClick = { 
                            currentMedia?.let { viewModel.toggleFavourite(it.contentId, isFavourite) }
                        }) {
                            Icon(
                                imageVector = if (isFavourite) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                                contentDescription = "Favorite",
                                tint = if (isFavourite) Color.Red else MaterialTheme.colorScheme.onSecondaryContainer
                            )
                        }

                        // 2. Edit
                        IconButton(onClick = {
                            currentMedia?.let { media ->
                                val intent = Intent(Intent.ACTION_EDIT).apply {
                                    setDataAndType(Uri.parse(media.uri), media.sourceMimeType)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                try {
                                    context.startActivity(Intent.createChooser(intent, "Edit Media"))
                                } catch (e: Exception) { }
                            }
                        }) {
                            Icon(Icons.Outlined.Edit, contentDescription = "Edit", tint = MaterialTheme.colorScheme.onSecondaryContainer)
                        }

                        // 3. Info
                        IconButton(onClick = { showInfo = true }) {
                            Icon(Icons.Outlined.Info, contentDescription = "Info", tint = MaterialTheme.colorScheme.onSecondaryContainer)
                        }

                        // 4. Share / Restore
                        if (currentMedia?.isTrashed == true) {
                            IconButton(onClick = {
                                currentMedia?.let { media ->
                                    viewModel.restoreMedia(media.contentId, media.uri)
                                    onBack()
                                }
                            }) {
                                Icon(Icons.Outlined.RestoreFromTrash, contentDescription = "Restore", tint = MaterialTheme.colorScheme.onSecondaryContainer)
                            }
                        } else {
                            IconButton(onClick = {
                                currentMedia?.let { media ->
                                    val uri = FileProvider.getUriForFile(context, "com.pixel.gallery.fileprovider", File(media.path))
                                    val intent = Intent(Intent.ACTION_SEND).apply {
                                        type = media.sourceMimeType
                                        putExtra(Intent.EXTRA_STREAM, uri)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                    context.startActivity(Intent.createChooser(intent, "Share Media"))
                                }
                            }) {
                                Icon(Icons.Outlined.Share, contentDescription = "Share", tint = MaterialTheme.colorScheme.onSecondaryContainer)
                            }
                        }

                        // 5. Delete
                        IconButton(onClick = {
                            if (currentMedia?.isTrashed == true) {
                                if (confirmDelete) {
                                    isPermanentDelete = true
                                    showDeleteConfirmDialog = true
                                } else {
                                    currentMedia?.let { media ->
                                        viewModel.deleteMediaBulk(listOf(media.uri))
                                        onBack()
                                    }
                                }
                            } else {
                                if (confirmTrash) {
                                    isPermanentDelete = false
                                    showDeleteConfirmDialog = true
                                } else {
                                    currentMedia?.let { media ->
                                        viewModel.moveToTrash(media.contentId, media.uri, media.path)
                                        onBack()
                                    }
                                }
                            }
                        }) {
                            Icon(Icons.Outlined.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.onSecondaryContainer)
                        }
                    }
                }
            }
        }

        if (showWallpaperSheet && currentMedia != null && canSetWallpaper) {
            ModalBottomSheet(
                onDismissRequest = { showWallpaperSheet = false }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 12.dp)
                        .navigationBarsPadding()
                ) {
                    Text(
                        text = "Set as wallpaper",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 12.dp)
                    )
                    ListItem(
                        headlineContent = { Text("Crop and set") },
                        supportingContent = { Text("Adjust the crop before applying it.") },
                        leadingContent = { Icon(Icons.Outlined.Crop, contentDescription = null) },
                        modifier = Modifier.clickable {
                            showWallpaperSheet = false
                            wallpaperCropMedia = currentMedia
                        }
                    )
                    ListItem(
                        headlineContent = { Text("Set directly") },
                        supportingContent = { Text("Apply the image without cropping.") },
                        leadingContent = { Icon(Icons.Outlined.Wallpaper, contentDescription = null) },
                        modifier = Modifier.clickable {
                            val media = currentMedia ?: return@clickable
                            showWallpaperSheet = false
                            wallpaperScope.launch {
                                wallpaperBusy = true
                                try {
                                    applyWallpaperFromMedia(context, media)
                                    wallpaperMessage = "Wallpaper applied."
                                } catch (e: Exception) {
                                    Log.e("ViewerScreen", "failed to set wallpaper directly for ${media.uri}", e)
                                    wallpaperMessage = "Could not set wallpaper."
                                } finally {
                                    wallpaperBusy = false
                                }
                            }
                        }
                    )
                    Spacer(Modifier.height(12.dp))
                }
            }
        }

        if (wallpaperCropMedia != null && canSetWallpaper) {
            WallpaperCropScreen(
                media = wallpaperCropMedia!!,
                onCancel = { wallpaperCropMedia = null },
                onConfirm = { bitmap ->
                    wallpaperCropMedia = null
                            wallpaperScope.launch {
                                wallpaperBusy = true
                                try {
                                    applyWallpaperBitmap(context, bitmap)
                                    wallpaperMessage = "Wallpaper applied."
                                } catch (e: Exception) {
                                    Log.e("ViewerScreen", "failed to set wallpaper from crop for ${currentMedia?.uri}", e)
                                    wallpaperMessage = "Could not set wallpaper."
                                } finally {
                                    wallpaperBusy = false
                                }
                            }
                }
            )
        }

        if (wallpaperBusy) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.35f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }

        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 88.dp)
        )

        if (showInfo && currentMedia != null) {
            InfoBottomSheet(
                media = currentMedia,
                viewModel = viewModel,
                onDismiss = { showInfo = false }
            )
        }

        if (showDeleteConfirmDialog && currentMedia != null) {
            DeleteConfirmationDialog(
                itemCount = 1,
                isPermanent = isPermanentDelete,
                onConfirm = { bypassTrash ->
                    if (isPermanentDelete || bypassTrash) {
                        viewModel.deleteMediaBulk(listOf(currentMedia.uri))
                    } else {
                        viewModel.moveToTrash(currentMedia.contentId, currentMedia.uri, currentMedia.path)
                    }
                    onBack()
                },
                onDismiss = {
                    showDeleteConfirmDialog = false
                }
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

private suspend fun loadWallpaperBitmap(
    context: android.content.Context,
    media: MediaEntry,
    targetSize: WallpaperImageSize,
): Bitmap? = withContext(Dispatchers.IO) {
    runCatching {
        Glide.with(context)
            .asBitmap()
            .load(media.uri)
            .submit(targetSize.width, targetSize.height)
            .get()
    }.getOrNull()?.let { bitmap ->
        if (MimeTypes.needRotationAfterGlide(media.sourceMimeType, null)) {
            BitmapUtils.applyExifOrientation(context, bitmap, media.sourceRotationDegrees, false)
        } else {
            bitmap
        }
    }
}

private suspend fun applyWallpaperBitmap(
    context: android.content.Context,
    bitmap: Bitmap,
) = withContext(Dispatchers.IO) {
    WallpaperManager.getInstance(context).setBitmap(bitmap)
}

private suspend fun applyWallpaperFromMedia(
    context: android.content.Context,
    media: MediaEntry,
) = withContext(Dispatchers.IO) {
    context.contentResolver.openInputStream(Uri.parse(media.uri))?.use { input ->
        WallpaperManager.getInstance(context).setStream(input)
    } ?: throw IllegalStateException("failed to open wallpaper input stream for ${media.uri}")
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
    isMuted: Boolean = false,
    onMuteChange: (Boolean) -> Unit = {},
    onTap: () -> Unit = {}
) {
    val context = LocalContext.current
    var exoPlayer by remember { mutableStateOf<ExoPlayer?>(null) }
    var isPlaying by remember { mutableStateOf(false) }

    DisposableEffect(exoPlayer) {
        val listener = object : Player.Listener {
            override fun onIsPlayingChanged(playing: Boolean) {
                isPlaying = playing
            }
        }
        exoPlayer?.addListener(listener)
        onDispose {
            exoPlayer?.removeListener(listener)
        }
    }

    DisposableEffect(isActive, uri) {
        val player = if (isActive) {
            ExoPlayer.Builder(context).build().apply {
                setMediaItem(MediaItem.fromUri(Uri.parse(uri)))
                repeatMode = if (isMotionPhoto) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
                volume = if (isMuted && !isMotionPhoto) 0f else 1f
                prepare()
                playWhenReady = isMotionPhoto
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
                        useController = false
                        player = exoPlayer
                        setBackgroundColor(android.graphics.Color.BLACK)
                    }
                },
                update = { view ->
                    view.player = exoPlayer
                    view.keepScreenOn = isPlaying
                    exoPlayer?.volume = if (isMuted) 0f else 1f
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
                    isMuted = isMuted,
                    onMuteChange = onMuteChange,
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
    isMuted: Boolean,
    onMuteChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    val configuration = LocalConfiguration.current
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

    var isPlaying by remember { mutableStateOf(player.isPlaying) }
    var currentPosition by remember { mutableLongStateOf(0L) }
    var duration by remember { mutableLongStateOf(0L) }
    var isDragging by remember { mutableStateOf(false) }

    DisposableEffect(player) {
        val listener = object : Player.Listener {
            override fun onIsPlayingChanged(isPlayingChanged: Boolean) {
                isPlaying = isPlayingChanged
            }
            override fun onPlaybackStateChanged(playbackState: Int) {
                duration = player.duration.coerceAtLeast(0L)
                isPlaying = player.isPlaying
            }
        }
        player.addListener(listener)
        onDispose {
            player.removeListener(listener)
        }
    }

    LaunchedEffect(player, isDragging) {
        while (true) {
            try {
                if (!isDragging) {
                    currentPosition = player.currentPosition
                }
                duration = player.duration.coerceAtLeast(0L)
            } catch (e: Exception) {
                break
            }
            delay(250)
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
                        if (player.playbackState == Player.STATE_ENDED) {
                            player.seekTo(0)
                            player.play()
                        } else {
                            if (player.isPlaying) player.pause() else player.play()
                        }
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

            Surface(
                shape = CircleShape,
                color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.85f),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = if (isLandscape) 85.dp else 115.dp)
                    .padding(horizontal = 24.dp)
                    .fillMaxWidth()
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = formatTime(currentPosition),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                    
                    Slider(
                        value = currentPosition.toFloat(),
                        onValueChange = { 
                            isDragging = true
                            currentPosition = it.toLong()
                        },
                        onValueChangeFinished = {
                            isDragging = false
                            try {
                                player.seekTo(currentPosition)
                            } catch (e: Exception) {}
                        },
                        valueRange = 0f..duration.toFloat().coerceAtLeast(1f),
                        colors = SliderDefaults.colors(
                            thumbColor = MaterialTheme.colorScheme.primary,
                            activeTrackColor = MaterialTheme.colorScheme.primary,
                            inactiveTrackColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                        ),
                        modifier = Modifier.weight(1f)
                    )
                    
                    Text(
                        text = formatTime(duration),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                    
                    IconButton(
                        onClick = {
                            onMuteChange(!isMuted)
                        }
                    ) {
                        Icon(
                            imageVector = if (isMuted) Icons.Default.VolumeOff else Icons.Default.VolumeUp,
                            contentDescription = if (isMuted) "Muted" else "Unmuted",
                            tint = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                    }
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
