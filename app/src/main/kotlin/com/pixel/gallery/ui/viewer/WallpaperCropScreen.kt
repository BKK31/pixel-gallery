package com.pixel.gallery.ui.viewer

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.bumptech.glide.Glide
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.utils.BitmapUtils
import com.pixel.gallery.utils.MimeTypes
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.max
import kotlin.math.roundToInt

private const val WALLPAPER_MAX_LONG_SIDE = 2048
private const val WALLPAPER_MAX_SCALE = 6f

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WallpaperCropScreen(
    media: MediaEntry,
    onCancel: () -> Unit,
    onConfirm: (Bitmap) -> Unit,
) {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()
    val cropHostBitmapState = produceState<WallpaperLoadState>(
        initialValue = WallpaperLoadState.Loading,
        key1 = media.uri,
        key2 = media.sourceMimeType,
        key3 = media.sourceRotationDegrees,
    ) {
        val sourceWidth = media.width ?: configuration.screenWidthDp.coerceAtLeast(1) * 2
        val sourceHeight = media.height ?: configuration.screenHeightDp.coerceAtLeast(1) * 2
        val targetSize = calculateWallpaperWorkingSize(
            sourceWidth = sourceWidth,
            sourceHeight = sourceHeight,
            maxLongSide = WALLPAPER_MAX_LONG_SIDE,
        )
        val bitmap = loadWallpaperBitmap(context, media, targetSize)
        value = if (bitmap != null) {
            WallpaperLoadState.Ready(bitmap)
        } else {
            WallpaperLoadState.Failed("Unable to load image for cropping.")
        }
    }

    val bitmap = (cropHostBitmapState.value as? WallpaperLoadState.Ready)?.bitmap
    var viewportSize by remember { mutableStateOf(WallpaperFrameSize(0, 0)) }
    var scale by remember(bitmap, viewportSize) { mutableFloatStateOf(1f) }
    var offsetX by remember(bitmap, viewportSize) { mutableFloatStateOf(0f) }
    var offsetY by remember(bitmap, viewportSize) { mutableFloatStateOf(0f) }

    val imageSize = remember(bitmap) {
        bitmap?.let { WallpaperImageSize(it.width, it.height) }
    }

    LaunchedEffect(bitmap, viewportSize) {
        val currentBitmap = bitmap ?: return@LaunchedEffect
        if (viewportSize.width <= 0 || viewportSize.height <= 0) return@LaunchedEffect
        scale = calculateWallpaperCoverScale(
            imageSize = WallpaperImageSize(currentBitmap.width, currentBitmap.height),
            frameSize = viewportSize,
        )
        offsetX = 0f
        offsetY = 0f
    }

    val transformState = rememberTransformableState { zoomChange, panChange, _ ->
        val currentBitmap = bitmap ?: return@rememberTransformableState
        if (viewportSize.width <= 0 || viewportSize.height <= 0) return@rememberTransformableState
        val imageSizeForTransform = WallpaperImageSize(currentBitmap.width, currentBitmap.height)
        val minScale = calculateWallpaperCoverScale(imageSizeForTransform, viewportSize)
        val nextScale = (scale * zoomChange).coerceIn(minScale, WALLPAPER_MAX_SCALE)
        val constrained = constrainWallpaperOffset(
            offsetX = offsetX + panChange.x,
            offsetY = offsetY + panChange.y,
            imageSize = imageSizeForTransform,
            frameSize = viewportSize,
            scale = nextScale,
        )
        scale = nextScale
        offsetX = constrained.first
        offsetY = constrained.second
    }

    BackHandler(onBack = onCancel)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        when (val state = cropHostBitmapState.value) {
            WallpaperLoadState.Loading -> {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            }
            is WallpaperLoadState.Failed -> {
                Text(
                    text = state.message,
                    color = Color.White,
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            is WallpaperLoadState.Ready -> {
                BoxWithConstraints(
                    modifier = Modifier
                        .fillMaxSize()
                        .onSizeChanged {
                            viewportSize = WallpaperFrameSize(it.width, it.height)
                        }
                ) {
                    WallpaperCropCanvas(
                        bitmap = state.bitmap,
                        imageSize = imageSize ?: WallpaperImageSize(state.bitmap.width, state.bitmap.height),
                        frameSize = viewportSize,
                        transformState = transformState,
                        scale = scale,
                        offsetX = offsetX,
                        offsetY = offsetY,
                        modifier = Modifier.fillMaxSize(),
                    )
                }
            }
        }

        TopAppBar(
            title = {
                Text(
                    text = "Crop wallpaper",
                    color = Color.White
                )
            },
            navigationIcon = {
                IconButton(onClick = onCancel) {
                    Icon(
                            imageVector = Icons.Default.ChevronLeft,
                            contentDescription = "Cancel",
                            tint = Color.White
                        )
                    }
            },
            actions = {
                Button(
                    onClick = {
                        coroutineScope.launch {
                            val readyState = cropHostBitmapState.value as? WallpaperLoadState.Ready ?: return@launch
                            val currentFrame = viewportSize
                            if (currentFrame.width <= 0 || currentFrame.height <= 0) return@launch
                            val currentImageSize = WallpaperImageSize(readyState.bitmap.width, readyState.bitmap.height)
                            val currentTransform = WallpaperTransform(scale = scale, offsetX = offsetX, offsetY = offsetY)
                            val croppedBitmap = cropWallpaperBitmap(
                                bitmap = readyState.bitmap,
                                imageSize = currentImageSize,
                                frameSize = currentFrame,
                                transform = currentTransform,
                            )
                            if (croppedBitmap != null) {
                                onConfirm(croppedBitmap)
                            }
                        }
                    },
                    enabled = cropHostBitmapState.value is WallpaperLoadState.Ready,
                ) {
                    Text("Set wallpaper")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Black.copy(alpha = 0.3f),
                titleContentColor = Color.White,
                navigationIconContentColor = Color.White,
                actionIconContentColor = Color.White,
            ),
            scrollBehavior = null,
            modifier = Modifier.padding(top = 0.dp)
        )

        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter)
        )
    }
}

@Composable
private fun WallpaperCropCanvas(
    bitmap: Bitmap,
    imageSize: WallpaperImageSize,
    frameSize: WallpaperFrameSize,
    transformState: androidx.compose.foundation.gestures.TransformableState,
    scale: Float,
    offsetX: Float,
    offsetY: Float,
    modifier: Modifier = Modifier,
) {
    androidx.compose.foundation.Canvas(
        modifier = modifier.transformable(transformState)
    ) {
        val drawnWidth = imageSize.width * scale
        val drawnHeight = imageSize.height * scale
        val dstOffsetX = (size.width - drawnWidth) / 2f + offsetX
        val dstOffsetY = (size.height - drawnHeight) / 2f + offsetY
        val dstOffset = androidx.compose.ui.unit.IntOffset(dstOffsetX.roundToInt(), dstOffsetY.roundToInt())
        val dstSize = IntSize(max(1, drawnWidth.roundToInt()), max(1, drawnHeight.roundToInt()))

        drawRect(Color.Black)
        withTransform({
            translate(dstOffset.x.toFloat(), dstOffset.y.toFloat())
        }) {
            drawContext.canvas.nativeCanvas.drawBitmap(
                bitmap,
                null,
                Rect(0, 0, dstSize.width, dstSize.height),
                null,
            )
        }

        val borderStroke = 2.dp.toPx()
        drawRect(
            color = Color.White.copy(alpha = 0.65f),
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = borderStroke)
        )
    }
}

private suspend fun loadWallpaperBitmap(
    context: Context,
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

private suspend fun cropWallpaperBitmap(
    bitmap: Bitmap,
    imageSize: WallpaperImageSize,
    frameSize: WallpaperFrameSize,
    transform: WallpaperTransform,
): Bitmap? = withContext(Dispatchers.Default) {
    val cropRect = calculateWallpaperCropRect(imageSize, frameSize, transform) ?: return@withContext null
    runCatching {
        val cropped = Bitmap.createBitmap(bitmap, cropRect.left, cropRect.top, cropRect.width, cropRect.height)
        if (cropRect.width == frameSize.width && cropRect.height == frameSize.height) {
            cropped
        } else {
            Bitmap.createScaledBitmap(cropped, frameSize.width, frameSize.height, true)
        }
    }.getOrNull()
}

private sealed interface WallpaperLoadState {
    data object Loading : WallpaperLoadState

    data class Ready(val bitmap: Bitmap) : WallpaperLoadState

    data class Failed(val message: String) : WallpaperLoadState
}
