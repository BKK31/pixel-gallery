package com.pixel.gallery.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.pixel.gallery.data.local.dao.MediaDao
import com.pixel.gallery.data.local.entity.MediaEntry
import com.pixel.gallery.data.local.entity.MetadataEntry
import com.pixel.gallery.data.local.entity.FavouriteEntry
import com.pixel.gallery.data.local.entity.TrashEntry
import com.pixel.gallery.data.local.entity.VaultEntry

@Database(
    entities = [
        MediaEntry::class,
        MetadataEntry::class,
        FavouriteEntry::class,
        TrashEntry::class,
        VaultEntry::class
    ],
    version = 3,
    exportSchema = false
)
abstract class GalleryDatabase : RoomDatabase() {
    abstract fun mediaDao(): MediaDao
}
