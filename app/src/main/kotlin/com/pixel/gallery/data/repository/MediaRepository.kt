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
import androidx.exifinterface.media.ExifInterface
import com.pixel.gallery.MainActivity
import com.pixel.gallery.data.local.dao.MediaDao
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.data.local.entity.VaultEntry
import com.google.gson.Gson
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MediaRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val mediaDao: MediaDao,
    private val settingsRepository: SettingsRepository
) {
    private val gson = Gson()
    val allEntries: Flow<List<MediaEntry>> = combine(
        mediaDao.getAllEntries(),
        settingsRepository.excludedFolders
    ) { entries, excluded ->
        entries.filter { entry ->
            !excluded.any { entry.path.startsWith(it) }
        }
    }

    val favourites: Flow<List<MediaEntry>> = combine(
        mediaDao.getFavourites(),
        settingsRepository.excludedFolders
    ) { entries, excluded ->
        entries.filter { entry ->
            !excluded.any { entry.path.startsWith(it) }
        }
    }

    val trash: Flow<List<MediaEntry>> = mediaDao.getTrash() 


    fun isFavourite(id: Long): Flow<Boolean> = mediaDao.isFavourite(id)

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

    // --- Vault ---
    suspend fun moveToVault(entry: MediaEntry): Boolean = withContext(Dispatchers.IO) {
        val vaultDir = java.io.File(context.getExternalFilesDir(null), "vault")
        if (!vaultDir.exists()) vaultDir.mkdirs()
        
        val originalFile = java.io.File(entry.path)
        val vaultFile = java.io.File(vaultDir, entry.contentId.toString())
        val originalLastModified = originalFile.lastModified()
        
        // Use copy + delete if rename fails (e.g. cross-volume)
        val moved = if (originalFile.renameTo(vaultFile)) {
            true
        } else {
            try {
                originalFile.copyTo(vaultFile, overwrite = true)
                vaultFile.setLastModified(originalLastModified)
                originalFile.delete()
                true
            } catch (e: Exception) {
                false
            }
        }

        if (moved) {
            val vaultEntry = VaultEntry(
                id = entry.contentId,
                vaultPath = vaultFile.absolutePath,
                originalPath = entry.path,
                entryJson = gson.toJson(entry)
            )
            mediaDao.insertVaultEntry(vaultEntry)
            
            // Delete from MediaStore
            context.contentResolver.delete(android.net.Uri.parse(entry.uri), null, null)
            
            // Manually remove from local DB so it disappears instantly
            mediaDao.deleteByIds(listOf(entry.contentId))
            true
        } else {
            false
        }
    }

    suspend fun restoreFromVault(id: Long): Boolean = withContext(Dispatchers.IO) {
        val vaultEntry = mediaDao.getVaultEntry(id) ?: return@withContext false
        val vaultFile = java.io.File(vaultEntry.vaultPath)
        val originalFile = java.io.File(vaultEntry.originalPath)
        val vaultLastModified = vaultFile.lastModified()
        
        val restored = if (vaultFile.renameTo(originalFile)) {
            true
        } else {
            try {
                vaultFile.copyTo(originalFile, overwrite = true)
                originalFile.setLastModified(vaultLastModified)
                vaultFile.delete()
                true
            } catch (e: Exception) {
                false
            }
        }

        if (restored) {
            val originalEntry = gson.fromJson(vaultEntry.entryJson, MediaEntry::class.java)
            mediaDao.deleteVaultEntry(id)
            
            // Rescan the file to add it back to MediaStore
            android.media.MediaScannerConnection.scanFile(context, arrayOf(originalFile.absolutePath), null) { _, uri ->
                if (uri != null) {
                    val values = android.content.ContentValues().apply {
                        put(android.provider.MediaStore.MediaColumns.DATE_ADDED, originalEntry.dateAddedSecs)
                        put(android.provider.MediaStore.MediaColumns.DATE_MODIFIED, originalEntry.dateModifiedMillis / 1000)
                        originalEntry.sourceDateTakenMillis?.let { put("datetaken", it) }
                    }
                    try {
                        context.contentResolver.update(uri, values, null, null)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
            true
        } else {
            false
        }
    }

    val vaultEntries: Flow<List<MediaEntry>> = mediaDao.getVaultEntries().map { list ->
        list.map { 
            val entry = gson.fromJson(it.entryJson, MediaEntry::class.java)
            // Update entry to point to vault path for correct rendering
            entry.copy(
                path = it.vaultPath,
                uri = Uri.fromFile(java.io.File(it.vaultPath)).toString()
            )
        }.sortedByDescending { it.bestTimestamp }
    }

    fun getContentResolver() = context.contentResolver

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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) MediaStore.Images.Media.DATE_TAKEN else MediaStore.MediaColumns.DATE_MODIFIED,
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
            val takenColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                cursor.getColumnIndex(MediaStore.Images.Media.DATE_TAKEN)
            } else -1

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                currentIds.add(id)
                val modified = cursor.getLong(modifiedColumn) * 1000
                val path = cursor.getString(dataColumn)

                // Also update if trashing status changed
                val knownEntry = knownEntries[id]
                if (knownEntry?.dateModifiedMillis != modified || knownEntry.isTrashed != queryTrashed) {
                    val mediaStoreTaken = if (takenColumn != -1) cursor.getLong(takenColumn) else 0L
                    
                    // DEEP SCAN: If mediaStore report "today" but it's an image, check EXIF
                    var bestTime = if (mediaStoreTaken > 0) mediaStoreTaken else (cursor.getLong(addedColumn) * 1000)
                    
                    val isRecentlyAdded = Math.abs(System.currentTimeMillis() - bestTime) < 600000 // 10 mins
                    
                    if (bestTime == 0L || isRecentlyAdded) { 
                        var foundExif = false
                        if (cursor.getString(mimeColumn).startsWith("image/")) {
                            try {
                                val exif = ExifInterface(path)
                                val exifTime = exif.dateTime
                                if (exifTime != null && exifTime > 0) {
                                    bestTime = exifTime
                                    foundExif = true
                                }
                            } catch (e: Exception) { }
                        }
                        
                        if (!foundExif) {
                            // Fallback to actual file system time if MediaStore is too recent (e.g. after restore)
                            val fileTime = java.io.File(path).lastModified()
                            if (fileTime > 0 && (bestTime == 0L || fileTime < bestTime - 10000)) {
                                bestTime = fileTime
                            }
                        }
                    }

                    if (bestTime == 0L) bestTime = modified

                    newEntries.add(
                        MediaEntry(
                            contentId = id,
                            uri = uri.buildUpon().appendPath(id.toString()).toString(),
                            path = path,
                            sourceMimeType = cursor.getString(mimeColumn),
                            width = cursor.getInt(widthColumn),
                            height = cursor.getInt(heightColumn),
                            sourceRotationDegrees = cursor.getInt(rotationColumn),
                            sizeBytes = cursor.getLong(sizeColumn),
                            dateAddedSecs = cursor.getLong(addedColumn),
                            dateModifiedMillis = modified,
                            sourceDateTakenMillis = if (mediaStoreTaken > 0) mediaStoreTaken else null,
                            durationMillis = cursor.getLong(durationColumn),
                            isTrashed = queryTrashed,
                            bestTimestamp = bestTime
                        )
                    )
                }
            }
        }
    }
}
