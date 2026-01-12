package com.pixel.gallery.decoding

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import androidx.annotation.RequiresApi
import androidx.core.graphics.scale
import androidx.core.net.toUri
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DecodeFormat
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.RequestOptions
import com.pixel.gallery.channel.streams.ByteSink
import com.pixel.gallery.model.EntryFields
import com.pixel.gallery.utils.BitmapUtils
import com.pixel.gallery.utils.BitmapUtils.applyExifOrientation
import com.pixel.gallery.utils.LogUtils
import com.pixel.gallery.utils.MimeTypes
import com.pixel.gallery.utils.MimeTypes.isVideo
import com.pixel.gallery.utils.MimeTypes.needRotationAfterContentResolverThumbnail
import com.pixel.gallery.utils.UriUtils.tryParseId
import java.io.ByteArrayInputStream
import kotlin.math.min
import kotlin.math.roundToInt

class ThumbnailFetcher internal constructor(
    private val context: Context,
    uri: String,
    private val pageId: Int?,
    private val decoded: Boolean,
    private val mimeType: String,
    private val dateModifiedMillis: Long,
    private val rotationDegrees: Int,
    private val isFlipped: Boolean,
    width: Int?,
    height: Int?,
    private val defaultSize: Int,
    private val quality: Int,
    private val result: ByteSink,
) {
    private val uri: Uri = uri.toUri()
    private val width: Int = if (width?.takeIf { it > 0 } != null) width else defaultSize
    private val height: Int = if (height?.takeIf { it > 0 } != null) height else defaultSize

    suspend fun fetch() {
        var bitmap: Bitmap? = null
        var exception: Exception? = null

        try {
            if ((width == defaultSize || height == defaultSize) && !isFlipped) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    bitmap = getByResolver()
                } else {
                    bitmap = getByMediaStore()
                }
            }
        } catch (e: Exception) {
            exception = e
        }

        if (bitmap == null) {
            try {
                bitmap = getByGlide()
            } catch (e: Exception) {
                exception = e
            }
        }

        if (bitmap != null) {
            if (bitmap.width > width && bitmap.height > height) {
                val scalingFactor: Double = min(bitmap.width.toDouble() / width, bitmap.height.toDouble() / height)
                val dstWidth = (bitmap.width / scalingFactor).roundToInt()
                val dstHeight = (bitmap.height / scalingFactor).roundToInt()
                bitmap = bitmap.scale(dstWidth, dstHeight)
            }
        }

        val bytes = BitmapUtils.getBytes(bitmap, recycle = false, decoded = decoded, mimeType)
        if (bytes == null) {
            result.error("getThumbnail-null", "failed to get thumbnail for mimeType=$mimeType uri=$uri", exception?.message)
        } else {
            result.streamBytes(ByteArrayInputStream(bytes))
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private fun getByResolver(): Bitmap? {
        val resolver = context.contentResolver
        return try {
            resolver.loadThumbnail(uri, Size(width, height), null)
        } catch (e: Exception) {
            null
        }
    }

    private fun getByMediaStore(): Bitmap? {
        val contentId = uri.tryParseId() ?: return null
        val resolver = context.contentResolver
        return if (isVideo(mimeType)) {
            @Suppress("deprecation")
            MediaStore.Video.Thumbnails.getThumbnail(resolver, contentId, MediaStore.Video.Thumbnails.MINI_KIND, null)
        } else {
            @Suppress("deprecation")
            var bitmap = MediaStore.Images.Thumbnails.getThumbnail(resolver, contentId, MediaStore.Images.Thumbnails.MINI_KIND, null)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q && bitmap != null) {
                bitmap = applyExifOrientation(context, bitmap, rotationDegrees, isFlipped)
            }
            bitmap
        }
    }

    private fun getByGlide(): Bitmap? {
        val options = RequestOptions()
            .format(if (quality == 100) DecodeFormat.PREFER_ARGB_8888 else DecodeFormat.PREFER_RGB_565)
            .override(width, height)
            
        val target = Glide.with(context)
            .asBitmap()
            .apply(options)
            .load(uri)
            .submit(width, height)

        return try {
            target.get()
        } catch (e: Exception) {
            null
        } finally {
            Glide.with(context).clear(target)
        }
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ThumbnailFetcher>()
    }
}
