package com.pixel.gallery.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "favourites")
data class FavouriteEntry(
    @PrimaryKey val id: Long
)

@Entity(tableName = "trash")
data class TrashEntry(
    @PrimaryKey val id: Long,
    val path: String,
    val dateMillis: Long
)

@Entity(tableName = "vault")
data class VaultEntry(
    @PrimaryKey val id: Long,
    val vaultPath: String,
    val originalPath: String,
    val entryJson: String
)
