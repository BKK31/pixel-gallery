package com.pixel.gallery.utils

import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.util.Log
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.bitmap.TransformationUtils
import com.pixel.gallery.metadata.Metadata.getExifCode
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.ByteArrayOutputStream

object BitmapUtils {
    private val LOG_TAG = LogUtils.createTag<BitmapUtils>()
    private const val INITIAL_BUFFER_SIZE = 1 shl 18 // 256kB

    private val freeBaos = ArrayList<ByteArrayOutputStream>()
    private val mutex = Mutex()

    private const val FORMAT_BYTE_ENCODED: Int = 0xCA
    val FORMAT_BYTE_ENCODED_AS_BYTES: ByteArray = ByteArray(1) { _ -> FORMAT_BYTE_ENCODED.toByte() }

    // bytes per pixel with different bitmap config
    private const val BPP_ALPHA_8 = 1
    private const val BPP_RGB_565 = 2
    private const val BPP_ARGB_8888 = 4
    private const val BPP_RGBA_1010102 = 4
    private const val BPP_RGBA_F16 = 8

    private fun getBytePerPixel(config: Bitmap.Config?): Int {
        return when (config) {
            Bitmap.Config.ALPHA_8 -> BPP_ALPHA_8
            Bitmap.Config.RGB_565 -> BPP_RGB_565
            Bitmap.Config.ARGB_8888 -> BPP_ARGB_8888
            else -> {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && config == Bitmap.Config.RGBA_F16) {
                    BPP_RGBA_F16
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && config == Bitmap.Config.RGBA_1010102) {
                    BPP_RGBA_1010102
                } else {
                    // default
                    BPP_ARGB_8888
                }
            }
        }
    }

    fun getExpectedImageSize(pixelCount: Long, config: Bitmap.Config?): Long {
        return pixelCount * getBytePerPixel(config)
    }

    suspend fun getBytes(bitmap: Bitmap?, recycle: Boolean, decoded: Boolean, mimeType: String?): ByteArray? {
        // Simplified: only supporting encoded bytes for now as Lumina simplified version
        return getEncodedBytes(bitmap, canHaveAlpha = MimeTypes.canHaveAlpha(mimeType), recycle = recycle)
    }

    private suspend fun getEncodedBytes(bitmap: Bitmap?, canHaveAlpha: Boolean = false, quality: Int = 100, recycle: Boolean): ByteArray? {
        bitmap ?: return null

        val stream: ByteArrayOutputStream
        mutex.withLock {
            stream = if (freeBaos.isNotEmpty()) {
                freeBaos.removeAt(0)
            } else {
                ByteArrayOutputStream(INITIAL_BUFFER_SIZE)
            }
        }
        try {
            if (canHaveAlpha && bitmap.hasAlpha()) {
                bitmap.compress(Bitmap.CompressFormat.PNG, quality, stream)
            } else {
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
            }
            if (recycle) bitmap.recycle()

            stream.write(FORMAT_BYTE_ENCODED)

            val bufferSize = stream.size()
            if (!MemoryUtils.canAllocate(bufferSize)) {
                throw Exception("bitmap compressed to $bufferSize bytes, which cannot be allocated to a new byte array")
            }

            val byteArray = stream.toByteArray()
            stream.reset()
            mutex.withLock {
                freeBaos.add(stream)
            }
            return byteArray
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to get bytes from bitmap", e)
        }
        return null
    }

    fun applyExifOrientation(context: Context, bitmap: Bitmap?, rotationDegrees: Int?, isFlipped: Boolean?): Bitmap? {
        if (bitmap == null || rotationDegrees == null || isFlipped == null) return bitmap
        if (rotationDegrees == 0 && !isFlipped) return bitmap
        val exifOrientation = getExifCode(rotationDegrees, isFlipped)
        return TransformationUtils.rotateImageExif(getBitmapPool(context), bitmap, exifOrientation)
    }

    fun getBitmapPool(context: Context) = Glide.get(context).bitmapPool
}
