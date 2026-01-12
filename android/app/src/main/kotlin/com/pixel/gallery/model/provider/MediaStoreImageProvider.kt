package com.pixel.gallery.model.provider

import android.annotation.SuppressLint
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import com.pixel.gallery.model.EntryFields
import com.pixel.gallery.model.FieldMap
import com.pixel.gallery.model.SourceEntry
import com.pixel.gallery.utils.LogUtils
import com.pixel.gallery.utils.MimeTypes
import com.pixel.gallery.utils.StorageUtils
import java.io.File
import java.io.IOException

class MediaStoreImageProvider : ImageProvider() {
    fun fetchAll(
        context: Context,
        knownEntries: Map<Long?, Long?>,
        directory: String?,
        handleNewEntry: NewEntryHandler,
    ) {
        Log.d(LOG_TAG, "fetching all media store items for ${knownEntries.size} known entries, directory=$directory")
        val isModified = fun(contentId: Long, dateModifiedMillis: Long): Boolean {
            val knownDate = knownEntries[contentId]
            return knownDate == null || knownDate < dateModifiedMillis
        }
        val handleNew: NewEntryHandler
        var selection: String? = null
        var selectionArgs: Array<String>? = null
        if (directory != null) {
            val relativePathDirectory = StorageUtils.ensureTrailingSeparator(directory)
            // simplified directory filtering
            selection = "${MediaStore.MediaColumns.DATA} LIKE ?"
            selectionArgs = arrayOf("$relativePathDirectory%")

            val parentCheckDirectory = StorageUtils.removeTrailingSeparator(directory)
            handleNew = { entry ->
                // skip entries in subfolders
                val path = entry[EntryFields.PATH] as String?
                if (path != null && File(path).parent == parentCheckDirectory) {
                    handleNewEntry(entry)
                }
            }
        } else {
            handleNew = handleNewEntry
        }
        fetchFrom(context, isModified, handleNew, IMAGE_CONTENT_URI, IMAGE_PROJECTION, selection, selectionArgs)
        fetchFrom(context, isModified, handleNew, VIDEO_CONTENT_URI, VIDEO_PROJECTION, selection, selectionArgs)
    }

    fun countAll(context: Context, selection: String? = null, selectionArgs: Array<String>? = null): Int {
        var total = 0
        fun count(uri: Uri) {
            try {
                val cursor = context.contentResolver.query(uri, arrayOf(MediaStore.MediaColumns._ID), selection, selectionArgs, null)
                if (cursor != null) {
                    total += cursor.count
                    cursor.close()
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "failed to count from $uri", e)
            }
        }
        count(IMAGE_CONTENT_URI)
        count(VIDEO_CONTENT_URI)
        return total
    }

    private fun fetchFrom(
        context: Context,
        isValidEntry: NewEntryChecker,
        handleNewEntry: NewEntryHandler,
        contentUri: Uri,
        projection: Array<String>,
        selection: String? = null,
        selectionArgs: Array<String>? = null,
        fileMimeType: String? = null,
    ): Boolean {
        var found = false
        val orderBy = "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"
        try {
            val cursor = context.contentResolver.query(contentUri, projection, selection, selectionArgs, orderBy)
            if (cursor != null) {
                val contentUriContainsId = when (contentUri) {
                    IMAGE_CONTENT_URI, VIDEO_CONTENT_URI -> false
                    else -> true
                }

                // image & video
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val widthColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH)
                val heightColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT)
                val dateAddedSecsColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED)
                val dateModifiedSecsColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                val dateTakenColumn = cursor.getColumnIndex(MediaColumns.DATE_TAKEN)

                // image & video for API >=29, only for images for API <29
                val orientationColumn = cursor.getColumnIndex(MediaColumns.ORIENTATION)

                // video only
                val durationColumn = cursor.getColumnIndex(MediaColumns.DURATION)
                val needDuration = projection.contentEquals(VIDEO_PROJECTION)

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    val dateModifiedMillis = cursor.getInt(dateModifiedSecsColumn) * 1000L
                    if (isValidEntry(id, dateModifiedMillis)) {
                        val itemUri = if (contentUriContainsId) contentUri else ContentUris.withAppendedId(contentUri, id)
                        val mimeType: String? = cursor.getString(mimeTypeColumn) ?: fileMimeType
                        var width = cursor.getInt(widthColumn)
                        var height = cursor.getInt(heightColumn)
                        val durationMillis = if (durationColumn != -1) cursor.getLong(durationColumn) else 0L

                        if (mimeType == null) {
                            Log.w(LOG_TAG, "failed to make entry from uri=$itemUri because of null MIME type")
                        } else {
                            val path = cursor.getString(pathColumn)

                            val isDir = path != null && File(path).isDirectory
                            if (isDir) {
                                Log.w(LOG_TAG, "failed to make entry from uri=$itemUri because path=$path refers to a directory")
                            } else {
                                var entryFields: FieldMap = hashMapOf(
                                    EntryFields.ORIGIN to SourceEntry.ORIGIN_MEDIA_STORE_CONTENT,
                                    EntryFields.URI to itemUri.toString(),
                                    EntryFields.PATH to path,
                                    EntryFields.SOURCE_MIME_TYPE to mimeType,
                                    EntryFields.WIDTH to width,
                                    EntryFields.HEIGHT to height,
                                    EntryFields.SOURCE_ROTATION_DEGREES to if (orientationColumn != -1) cursor.getInt(orientationColumn) else 0,
                                    EntryFields.SIZE_BYTES to cursor.getLong(sizeColumn),
                                    EntryFields.DATE_ADDED_SECS to cursor.getInt(dateAddedSecsColumn).toLong(),
                                    EntryFields.DATE_MODIFIED_MILLIS to dateModifiedMillis,
                                    EntryFields.SOURCE_DATE_TAKEN_MILLIS to if (dateTakenColumn != -1) cursor.getLong(dateTakenColumn) else null,
                                    EntryFields.DURATION_MILLIS to durationMillis,
                                    EntryFields.CONTENT_ID to id,
                                )

                                if (width <= 0 || height <= 0 || (durationMillis == 0L && needDuration)) {
                                    val entry = SourceEntry(entryFields).fillPreCatalogMetadata(context)
                                    entryFields = entry.toMap()
                                }

                                handleNewEntry(entryFields)
                                found = true
                            }
                        }
                    }
                }
                cursor.close()
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to fetch from contentUri=$contentUri", e)
        }
        return found
    }

    fun checkObsoleteContentIds(context: Context, knownContentIds: List<Long?>): List<Long> {
        val foundContentIds = HashSet<Long>()
        fun check(context: Context, contentUri: Uri) {
            val projection = arrayOf(MediaStore.MediaColumns._ID)
            try {
                val cursor = context.contentResolver.query(contentUri, projection, null, null, null)
                if (cursor != null) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    while (cursor.moveToNext()) {
                        foundContentIds.add(cursor.getLong(idColumn))
                    }
                    cursor.close()
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "failed to get content IDs for contentUri=$contentUri", e)
            }
        }
        check(context, IMAGE_CONTENT_URI)
        check(context, VIDEO_CONTENT_URI)
        return knownContentIds.subtract(foundContentIds).filterNotNull().toList()
    }

    fun checkObsoletePaths(context: Context, knownPathById: Map<Long?, String?>): List<Long> {
        val obsoleteIds = ArrayList<Long>()
        fun check(context: Context, contentUri: Uri) {
            val projection = arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DATA)
            try {
                val cursor = context.contentResolver.query(contentUri, projection, null, null, null)
                if (cursor != null) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(idColumn)
                        val path = cursor.getString(pathColumn)
                        if (knownPathById.containsKey(id) && knownPathById[id] != path) {
                            obsoleteIds.add(id)
                        }
                    }
                    cursor.close()
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "failed to get content IDs for contentUri=$contentUri", e)
            }
        }
        check(context, IMAGE_CONTENT_URI)
        check(context, VIDEO_CONTENT_URI)
        return obsoleteIds
    }

    fun getChangedUris(context: Context, sinceGeneration: Int): List<String> {
        val changedUris = ArrayList<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            fun check(context: Context, contentUri: Uri) {
                val projection = arrayOf(MediaStore.MediaColumns._ID)
                val selection = "${MediaStore.MediaColumns.GENERATION_MODIFIED} > ?"
                val selectionArgs = arrayOf(sinceGeneration.toString())
                try {
                    val cursor = context.contentResolver.query(contentUri, projection, selection, selectionArgs, null)
                    if (cursor != null) {
                        val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                        while (cursor.moveToNext()) {
                            val id = cursor.getLong(idColumn)
                            changedUris.add(ContentUris.withAppendedId(contentUri, id).toString())
                        }
                        cursor.close()
                    }
                } catch (e: Exception) {
                    Log.e(LOG_TAG, "failed to get content IDs for contentUri=$contentUri", e)
                }
            }
            check(context, IMAGE_CONTENT_URI)
            check(context, VIDEO_CONTENT_URI)
        }
        return changedUris
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<MediaStoreImageProvider>()

        private val IMAGE_CONTENT_URI = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        private val VIDEO_CONTENT_URI = MediaStore.Video.Media.EXTERNAL_CONTENT_URI

        private val BASE_PROJECTION = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.WIDTH,
            MediaStore.MediaColumns.HEIGHT,
            MediaStore.MediaColumns.DATE_ADDED,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaColumns.DATE_TAKEN,
        )

        private val IMAGE_PROJECTION = arrayOf(
            *BASE_PROJECTION,
            MediaColumns.ORIENTATION,
        )

        private val VIDEO_PROJECTION = arrayOf(
            *BASE_PROJECTION,
            MediaColumns.DURATION,
            *if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) arrayOf(
                MediaStore.MediaColumns.ORIENTATION,
            ) else emptyArray()
        )
    }
}

object MediaColumns {
    @SuppressLint("InlinedApi")
    const val DATE_TAKEN = "datetaken"

    @SuppressLint("InlinedApi")
    const val ORIENTATION = "orientation"

    @SuppressLint("InlinedApi")
    const val DURATION = "duration"
}

typealias NewEntryHandler = (entry: FieldMap) -> Unit

private typealias NewEntryChecker = (contentId: Long, dateModifiedMillis: Long) -> Boolean
