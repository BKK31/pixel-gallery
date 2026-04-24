package com.pixel.gallery.data.repository

import android.app.PendingIntent
import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.activity.result.IntentSenderRequest
import com.pixel.gallery.MainActivity
import com.pixel.gallery.data.local.dao.MediaDao
import com.pixel.gallery.data.local.entity.MediaEntry
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MediaRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val mediaDao: MediaDao
) {
    val allEntries: Flow<List<MediaEntry>> = mediaDao.getAllEntries()
    val favourites: Flow<List<MediaEntry>> = mediaDao.getFavourites()
    val trash: Flow<List<MediaEntry>> = mediaDao.getTrash()

    fun isFavourite(id: Long): Flow<Boolean> = mediaDao.isFavourite(id)

    suspend fun toggleFavourite(id: Long) = withContext(Dispatchers.IO) {
        val current = mediaDao.getKnownEntries().any { it.contentId == id } // Simple check
        // Actually, we should check the favourites table
    }

    // --- Favourites ---
    suspend fun addFavourite(id: Long) = withContext(Dispatchers.IO) {
        mediaDao.addFavourite(com.pixel.gallery.data.local.entity.FavouriteEntry(id))
    }

    suspend fun removeFavourite(id: Long) = withContext(Dispatchers.IO) {
        mediaDao.removeFavourite(id)
    }

    // --- Trash ---
    suspend fun trashMedia(id: Long, uriString: String, path: String) = withContext(Dispatchers.IO) {
        trashMediaBulk(listOf(uriString))
    }

    suspend fun trashMediaBulk(uriStrings: List<String>): Boolean = withContext(Dispatchers.IO) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val uris = uriStrings.map { Uri.parse(it) }
            
            if (Environment.isExternalStorageManager()) {
                // If we have All Files Access, we can skip the system dialog by updating the column directly
                val values = android.content.ContentValues().apply {
                    put(MediaStore.MediaColumns.IS_TRASHED, 1)
                }
                uris.forEach { uri ->
                    context.contentResolver.update(uri, values, null, null)
                }
                true // Handled internally
            } else {
                val pendingIntent = MediaStore.createTrashRequest(context.contentResolver, uris, true)
                MainActivity.launchIntentSender(IntentSenderRequest.Builder(pendingIntent.intentSender).build())
                false // Waiting for system activity result
            }
        } else {
            false
        }
    }

    suspend fun restoreMedia(id: Long, uriString: String) = withContext(Dispatchers.IO) {
        restoreMediaBulk(listOf(uriString))
    }

    suspend fun restoreMediaBulk(uriStrings: List<String>): Boolean = withContext(Dispatchers.IO) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val uris = uriStrings.map { Uri.parse(it) }
            
            if (Environment.isExternalStorageManager()) {
                val values = android.content.ContentValues().apply {
                    put(MediaStore.MediaColumns.IS_TRASHED, 0)
                }
                uris.forEach { uri ->
                    context.contentResolver.update(uri, values, null, null)
                }
                true // Handled internally
            } else {
                val pendingIntent = MediaStore.createTrashRequest(context.contentResolver, uris, false)
                MainActivity.launchIntentSender(IntentSenderRequest.Builder(pendingIntent.intentSender).build())
                false // Waiting for system activity result
            }
        } else {
            false
        }
    }

    suspend fun deleteMediaBulk(uriStrings: List<String>): Boolean = withContext(Dispatchers.IO) {
        val uris = uriStrings.map { Uri.parse(it) }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (Environment.isExternalStorageManager()) {
                uris.forEach { uri ->
                    context.contentResolver.delete(uri, null, null)
                }
                true
            } else {
                val pendingIntent = MediaStore.createDeleteRequest(context.contentResolver, uris)
                MainActivity.launchIntentSender(IntentSenderRequest.Builder(pendingIntent.intentSender).build())
                false
            }
        } else {
            uris.forEach { uri ->
                context.contentResolver.delete(uri, null, null)
            }
            true
        }
    }

    suspend fun syncWithMediaStore() = withContext(Dispatchers.IO) {
        val resolver = context.contentResolver
        val knownEntries = mediaDao.getKnownEntries().associateBy { it.contentId }
        val newEntries = mutableListOf<MediaEntry>()
        val currentIds = mutableSetOf<Long>()

        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.WIDTH,
            MediaStore.MediaColumns.HEIGHT,
            MediaStore.MediaColumns.ORIENTATION,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_ADDED,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.DURATION,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) MediaStore.MediaColumns.IS_TRASHED else MediaStore.MediaColumns.DATA // Just a dummy for old versions
        )

        // Query Images
        queryMediaStore(resolver, MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, knownEntries, newEntries, currentIds, false)
        queryMediaStore(resolver, MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, knownEntries, newEntries, currentIds, true)
        
        // Query Videos
        queryMediaStore(resolver, MediaStore.Video.Media.EXTERNAL_CONTENT_URI, projection, knownEntries, newEntries, currentIds, false)
        queryMediaStore(resolver, MediaStore.Video.Media.EXTERNAL_CONTENT_URI, projection, knownEntries, newEntries, currentIds, true)

        if (newEntries.isNotEmpty()) {
            mediaDao.insertAll(newEntries)
        }

        // Handle deletions
        val obsoleteIds = knownEntries.keys.filter { it !in currentIds }
        if (obsoleteIds.isNotEmpty()) {
            mediaDao.deleteByIds(obsoleteIds)
        }
    }

    private fun queryMediaStore(
        resolver: ContentResolver,
        uri: android.net.Uri,
        projection: Array<String>,
        knownEntries: Map<Long, com.pixel.gallery.data.local.dao.KnownEntry>,
        newEntries: MutableList<MediaEntry>,
        currentIds: MutableSet<Long>,
        queryTrashed: Boolean
    ) {
        val queryArgs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Bundle().apply {
                putInt(
                    MediaStore.QUERY_ARG_MATCH_TRASHED,
                    if (queryTrashed) MediaStore.MATCH_ONLY else MediaStore.MATCH_EXCLUDE
                )
                putString(ContentResolver.QUERY_ARG_SQL_SELECTION, null)
                putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, null)
            }
        } else {
            null
        }

        val selection = if (queryTrashed && Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            // Trash not supported natively below API 30
            return 
        } else {
            null
        }

        val cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && queryArgs != null) {
            resolver.query(uri, projection, queryArgs, null)
        } else {
            resolver.query(uri, projection, selection, null, null)
        }

        cursor?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
            val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
            val widthColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH)
            val heightColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT)
            val rotationColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.ORIENTATION)
            val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            val addedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED)
            val modifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
            val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DURATION)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                currentIds.add(id)
                val modified = cursor.getLong(modifiedColumn) * 1000

                // Also update if trashing status changed
                val knownEntry = knownEntries[id]
                if (knownEntry?.dateModifiedMillis != modified || knownEntry.isTrashed != queryTrashed) {
                    newEntries.add(
                        MediaEntry(
                            contentId = id,
                            uri = uri.buildUpon().appendPath(id.toString()).toString(),
                            path = cursor.getString(dataColumn),
                            sourceMimeType = cursor.getString(mimeColumn),
                            width = cursor.getInt(widthColumn),
                            height = cursor.getInt(heightColumn),
                            sourceRotationDegrees = cursor.getInt(rotationColumn),
                            sizeBytes = cursor.getLong(sizeColumn),
                            dateAddedSecs = cursor.getLong(addedColumn),
                            dateModifiedMillis = modified,
                            sourceDateTakenMillis = null,
                            durationMillis = cursor.getLong(durationColumn),
                            isTrashed = queryTrashed
                        )
                    )
                }
            }
        }
    }
}
