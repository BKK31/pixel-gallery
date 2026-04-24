package com.pixel.gallery.data.local.dao

import androidx.room.*
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.data.local.entity.MetadataEntry
import com.pixel.gallery.data.local.entity.FavouriteEntry
import com.pixel.gallery.data.local.entity.TrashEntry
import kotlinx.coroutines.flow.Flow

@Dao
interface MediaDao {
    
    // --- All Media ---
    @Query("SELECT * FROM media_entries WHERE isTrashed = 0 ORDER BY dateModifiedMillis DESC")
    fun getAllEntries(): Flow<List<MediaEntry>>

    @Query("SELECT contentId, dateModifiedMillis, isTrashed FROM media_entries")
    suspend fun getKnownEntries(): List<KnownEntry>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entries: List<MediaEntry>)

    @Query("DELETE FROM media_entries WHERE contentId IN (:ids)")
    suspend fun deleteByIds(ids: List<Long>)

    // --- Favourites ---
    @Query("SELECT * FROM media_entries WHERE isTrashed = 0 AND contentId IN (SELECT id FROM favourites) ORDER BY dateModifiedMillis DESC")
    fun getFavourites(): Flow<List<MediaEntry>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addFavourite(favourite: FavouriteEntry)

    @Query("DELETE FROM favourites WHERE id = :id")
    suspend fun removeFavourite(id: Long)

    @Query("SELECT EXISTS(SELECT 1 FROM favourites WHERE id = :id)")
    fun isFavourite(id: Long): Flow<Boolean>

    // --- Trash ---
    @Query("SELECT * FROM media_entries WHERE isTrashed = 1 ORDER BY dateModifiedMillis DESC")
    fun getTrash(): Flow<List<MediaEntry>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun moveToTrash(trashEntry: TrashEntry)

    @Query("DELETE FROM trash WHERE id = :id")
    suspend fun removeFromTrash(id: Long)

    // --- Metadata ---
    @Query("SELECT * FROM media_metadata WHERE id = :id")
    suspend fun getMetadata(id: Long): MetadataEntry?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMetadata(metadata: MetadataEntry)
}

data class KnownEntry(
    val contentId: Long,
    val dateModifiedMillis: Long,
    val isTrashed: Boolean
)
