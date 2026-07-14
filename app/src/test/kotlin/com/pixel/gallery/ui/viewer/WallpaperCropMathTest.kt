package com.pixel.gallery.ui.viewer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class WallpaperCropMathTest {

    @Test
    fun `cover scale uses the larger ratio`() {
        val scale = calculateWallpaperCoverScale(
            imageSize = WallpaperImageSize(4000, 3000),
            frameSize = WallpaperFrameSize(1080, 1920),
        )

        assertEquals(0.64f, scale, 0.0001f)
    }

    @Test
    fun `working size clamps the long side while preserving aspect`() {
        val size = calculateWallpaperWorkingSize(
            sourceWidth = 4000,
            sourceHeight = 3000,
            maxLongSide = 2000,
        )

        assertEquals(2000, size.width)
        assertEquals(1500, size.height)
    }

    @Test
    fun `crop rect maps a centered wallpaper frame back to source pixels`() {
        val crop = calculateWallpaperCropRect(
            imageSize = WallpaperImageSize(400, 200),
            frameSize = WallpaperFrameSize(100, 100),
            transform = WallpaperTransform(scale = 0.5f, offsetX = 0f, offsetY = 0f),
        )

        assertNotNull(crop)
        assertEquals(100, crop!!.left)
        assertEquals(0, crop.top)
        assertEquals(200, crop.width)
        assertEquals(200, crop.height)
    }

    @Test
    fun `offsets clamp to keep the image covering the frame`() {
        val constrained = constrainWallpaperOffset(
            offsetX = 500f,
            offsetY = -500f,
            imageSize = WallpaperImageSize(400, 200),
            frameSize = WallpaperFrameSize(100, 100),
            scale = 0.5f,
        )

        assertEquals(50f, constrained.first, 0.0001f)
        assertEquals(-0f, constrained.second, 0.0001f)
    }
}

