package com.pixel.gallery.ui.viewer

import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

data class WallpaperImageSize(val width: Int, val height: Int)

data class WallpaperFrameSize(val width: Int, val height: Int)

data class WallpaperTransform(
    val scale: Float,
    val offsetX: Float,
    val offsetY: Float,
)

data class WallpaperCropRect(
    val left: Int,
    val top: Int,
    val width: Int,
    val height: Int,
)

fun calculateWallpaperCoverScale(
    imageSize: WallpaperImageSize,
    frameSize: WallpaperFrameSize,
): Float {
    require(imageSize.width > 0 && imageSize.height > 0) { "image size must be positive" }
    require(frameSize.width > 0 && frameSize.height > 0) { "frame size must be positive" }
    return max(
        frameSize.width.toFloat() / imageSize.width,
        frameSize.height.toFloat() / imageSize.height,
    )
}

fun calculateWallpaperWorkingSize(
    sourceWidth: Int,
    sourceHeight: Int,
    maxLongSide: Int,
): WallpaperImageSize {
    require(sourceWidth > 0 && sourceHeight > 0) { "source size must be positive" }
    require(maxLongSide > 0) { "maxLongSide must be positive" }

    val longestSide = max(sourceWidth, sourceHeight)
    if (longestSide <= maxLongSide) {
        return WallpaperImageSize(sourceWidth, sourceHeight)
    }

    val scale = maxLongSide.toFloat() / longestSide.toFloat()
    return WallpaperImageSize(
        width = max(1, (sourceWidth * scale).roundToInt()),
        height = max(1, (sourceHeight * scale).roundToInt()),
    )
}

fun constrainWallpaperOffset(
    offsetX: Float,
    offsetY: Float,
    imageSize: WallpaperImageSize,
    frameSize: WallpaperFrameSize,
    scale: Float,
): Pair<Float, Float> {
    val scaledWidth = imageSize.width * scale
    val scaledHeight = imageSize.height * scale
    val maxOffsetX = max(0f, (scaledWidth - frameSize.width) / 2f)
    val maxOffsetY = max(0f, (scaledHeight - frameSize.height) / 2f)
    return Pair(
        offsetX.coerceIn(-maxOffsetX, maxOffsetX),
        offsetY.coerceIn(-maxOffsetY, maxOffsetY),
    )
}

fun calculateWallpaperCropRect(
    imageSize: WallpaperImageSize,
    frameSize: WallpaperFrameSize,
    transform: WallpaperTransform,
): WallpaperCropRect? {
    if (imageSize.width <= 0 || imageSize.height <= 0) return null
    if (frameSize.width <= 0 || frameSize.height <= 0) return null
    if (transform.scale <= 0f) return null

    val scaledWidth = imageSize.width * transform.scale
    val scaledHeight = imageSize.height * transform.scale
    val leftInFrame = (frameSize.width - scaledWidth) / 2f + transform.offsetX
    val topInFrame = (frameSize.height - scaledHeight) / 2f + transform.offsetY

    val left = floor((-leftInFrame) / transform.scale).toInt().coerceIn(0, imageSize.width - 1)
    val top = floor((-topInFrame) / transform.scale).toInt().coerceIn(0, imageSize.height - 1)
    val right = ceil((frameSize.width - leftInFrame) / transform.scale).toInt().coerceIn(left + 1, imageSize.width)
    val bottom = ceil((frameSize.height - topInFrame) / transform.scale).toInt().coerceIn(top + 1, imageSize.height)

    val width = right - left
    val height = bottom - top
    if (width <= 0 || height <= 0) return null

    return WallpaperCropRect(left, top, width, height)
}

