package com.pixel.gallery.model

import android.content.Context
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import androidx.core.net.toUri
import androidx.exifinterface.media.ExifInterface
import com.pixel.gallery.metadata.Metadata
import com.pixel.gallery.metadata.Metadata.getRotationDegreesForExifCode
import com.pixel.gallery.utils.MimeTypes
import com.pixel.gallery.utils.StorageUtils
import java.io.IOException

class SourceEntry {
    private val origin: Int
    val uri: Uri // content or file URI
    var path: String? = null // best effort to get local path
    private val sourceMimeType: String
    private var title: String? = null
    var width: Int? = null
    var height: Int? = null
    private var sourceRotationDegrees: Int? = null
    private var sizeBytes: Long? = null
    private var dateAddedSecs: Long? = null
    private var dateModifiedMillis: Long? = null
    private var sourceDateTakenMillis: Long? = null
    private var durationMillis: Long? = null

    // only for MediaStore
    var contentId: Long? = null

    constructor(origin: Int, uri: Uri, sourceMimeType: String) {
        this.origin = origin
        this.uri = uri
        this.sourceMimeType = sourceMimeType
    }

    constructor(map: FieldMap) {
        origin = map[EntryFields.ORIGIN] as Int
        uri = (map[EntryFields.URI] as String).toUri()
        path = map[EntryFields.PATH] as String?
        sourceMimeType = map[EntryFields.SOURCE_MIME_TYPE] as String
        width = map[EntryFields.WIDTH] as Int?
        height = map[EntryFields.HEIGHT] as Int?
        sourceRotationDegrees = map[EntryFields.SOURCE_ROTATION_DEGREES] as Int?
        sizeBytes = toLong(map[EntryFields.SIZE_BYTES])
        title = map[EntryFields.TITLE] as String?
        dateAddedSecs = toLong(map[EntryFields.DATE_ADDED_SECS])
        dateModifiedMillis = toLong(map[EntryFields.DATE_MODIFIED_MILLIS])
        sourceDateTakenMillis = toLong(map[EntryFields.SOURCE_DATE_TAKEN_MILLIS])
        durationMillis = toLong(map[EntryFields.DURATION_MILLIS])
        contentId = toLong(map[EntryFields.CONTENT_ID])
    }

    fun toMap(): FieldMap {
        return hashMapOf(
            EntryFields.ORIGIN to origin,
            EntryFields.URI to uri.toString(),
            EntryFields.PATH to path,
            EntryFields.SOURCE_MIME_TYPE to sourceMimeType,
            EntryFields.WIDTH to width,
            EntryFields.HEIGHT to height,
            EntryFields.SOURCE_ROTATION_DEGREES to (sourceRotationDegrees ?: 0),
            EntryFields.SIZE_BYTES to sizeBytes,
            EntryFields.TITLE to title,
            EntryFields.DATE_ADDED_SECS to dateAddedSecs,
            EntryFields.DATE_MODIFIED_MILLIS to dateModifiedMillis,
            EntryFields.SOURCE_DATE_TAKEN_MILLIS to sourceDateTakenMillis,
            EntryFields.DURATION_MILLIS to durationMillis,
            EntryFields.CONTENT_ID to contentId,
        )
    }

    fun fillPreCatalogMetadata(context: Context): SourceEntry {
        if (MimeTypes.isImage(sourceMimeType)) {
            if (sourceMimeType == MimeTypes.TIFF || sourceMimeType == MimeTypes.SVG) {
                // TODO special handling if needed
            } else {
                fillByExif(context)
            }
        } else if (MimeTypes.isVideo(sourceMimeType)) {
            fillByMetadataRetriever(context)
        }
        return this
    }

    private fun fillByExif(context: Context) {
        try {
            Metadata.openSafeInputStream(context, uri, sourceMimeType, sizeBytes)?.use { input ->
                val exifInterface = ExifInterface(input)
                width = exifInterface.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, width ?: 0)
                height = exifInterface.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, height ?: 0)
                sourceRotationDegrees = getRotationDegreesForExifCode(exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL))
            }
        } catch (e: Exception) {
            // ignore
        }
    }

    private fun fillByMetadataRetriever(context: Context) {
        val retriever = StorageUtils.openMetadataRetriever(context, uri) ?: return
        try {
            width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: width
            height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: height
            sourceRotationDegrees = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: sourceRotationDegrees
            durationMillis = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: durationMillis
        } catch (e: Exception) {
            // ignore
        } finally {
            retriever.release()
        }
    }

    companion object {
        const val ORIGIN_MEDIA_STORE_CONTENT = 1

        private fun toLong(o: Any?): Long? = when (o) {
            is Int -> o.toLong()
            else -> o as? Long
        }
    }
}
