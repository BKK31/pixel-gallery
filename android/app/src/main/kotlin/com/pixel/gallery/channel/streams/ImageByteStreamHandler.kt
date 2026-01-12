package com.pixel.gallery.channel.streams

import android.content.Context
import com.pixel.gallery.decoding.ThumbnailFetcher
import com.pixel.gallery.model.EntryFields
import com.pixel.gallery.utils.LogUtils
import kotlinx.coroutines.launch
import java.io.InputStream
import java.util.Date

class ImageByteStreamHandler(private val context: Context, private val arguments: Any?) : BaseStreamHandler(), ByteSink {
    private var op: String? = null
    private var decoded: Boolean = false

    init {
        if (arguments is Map<*, *>) {
            op = arguments["op"] as String?
            decoded = arguments["decoded"] as Boolean
        }
    }

    override val logTag = LOG_TAG

    override fun onCall(args: Any?) {
        when (op) {
            "getThumbnail" -> ioScope.launch { safeSuspend(::streamThumbnail) }
            else -> endOfStream()
        }
    }

    private suspend fun streamThumbnail() {
        if (arguments !is Map<*, *>) {
            return
        }

        val uri = arguments[EntryFields.URI] as String?
        val pageId = arguments["pageId"] as Int?
        val mimeType = arguments[EntryFields.MIME_TYPE] as String?
        val dateModifiedMillis = (arguments[EntryFields.DATE_MODIFIED_MILLIS] as Number?)?.toLong()
        val rotationDegrees = arguments[EntryFields.ROTATION_DEGREES] as Int?
        val isFlipped = arguments[EntryFields.IS_FLIPPED] as Boolean?
        val widthDip = (arguments["widthDip"] as Number?)?.toDouble()
        val heightDip = (arguments["heightDip"] as Number?)?.toDouble()
        val defaultSizeDip = (arguments["defaultSizeDip"] as Number?)?.toDouble()
        val quality = arguments["quality"] as Int?

        if (uri == null || mimeType == null || rotationDegrees == null || isFlipped == null || widthDip == null || heightDip == null || defaultSizeDip == null || quality == null) {
            error("getThumbnail-args", "missing arguments", null)
            return
        }

        val density = context.resources.displayMetrics.density
        
        ThumbnailFetcher(
            context = context,
            uri = uri,
            pageId = pageId,
            decoded = decoded,
            mimeType = mimeType,
            dateModifiedMillis = dateModifiedMillis ?: (Date().time),
            rotationDegrees = rotationDegrees,
            isFlipped = isFlipped,
            width = (widthDip * density).toInt(),
            height = (heightDip * density).toInt(),
            defaultSize = (defaultSizeDip * density).toInt(),
            quality = quality,
            result = this,
        ).fetch()
        endOfStream()
    }

    override fun streamBytes(inputStream: InputStream): Boolean {
        val buffer = ByteArray(BUFFER_SIZE)
        var len: Int
        try {
            while (inputStream.read(buffer).also { len = it } != -1) {
                success(buffer.copyOfRange(0, len))
            }
            success(202) // magic byte to signal end of encoded bytes
            return true
        } catch (e: Exception) {
            error("streamBytes-exception", e.message, e.stackTraceToString())
        } finally {
            inputStream.close()
        }
        return false
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        super.error(errorCode, errorMessage, errorDetails)
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ImageByteStreamHandler>()
        const val CHANNEL = "com.pixel.gallery/media_byte_stream"
    }
}

interface ByteSink {
    fun streamBytes(inputStream: InputStream): Boolean
    fun error(errorCode: String, errorMessage: String?, errorDetails: Any?)
}
