package com.pixel.gallery.utils

import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.util.Log
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.bitmap.TransformationUtils
import com.pixel.gallery.metadata.Metadata.getExifCode
import java.io.ByteArrayOutputStream
import java.io.InputStream

object BitmapUtils {
    private val LOG_TAG = LogUtils.createTag<BitmapUtils>()
    private const val INITIAL_BUFFER_SIZE = 1 shl 18 // 256kB

    private const val FORMAT_BYTE_ENCODED: Int = 0xCA
    val FORMAT_BYTE_ENCODED_AS_BYTES: ByteArray = ByteArray(1) { _ -> FORMAT_BYTE_ENCODED.toByte() }

    fun getBytes(bitmap: Bitmap?, recycle: Boolean, decoded: Boolean, mimeType: String?): ByteArray? {
        // Simplified: only supporting encoded bytes for now
        return getEncodedBytes(bitmap, canHaveAlpha = MimeTypes.canHaveAlpha(mimeType), recycle = recycle)
    }

    private fun getEncodedBytes(bitmap: Bitmap?, canHaveAlpha: Boolean = false, quality: Int = 100, recycle: Boolean): ByteArray? {
        bitmap ?: return null

        val stream = ByteArrayOutputStream(INITIAL_BUFFER_SIZE)
        try {
            if (canHaveAlpha && bitmap.hasAlpha()) {
                bitmap.compress(Bitmap.CompressFormat.PNG, quality, stream)
            } else {
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
            }
            if (recycle) bitmap.recycle()

            // trailer byte to indicate whether the returned bytes are decoded/encoded
            stream.write(FORMAT_BYTE_ENCODED)

            return stream.toByteArray()
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
