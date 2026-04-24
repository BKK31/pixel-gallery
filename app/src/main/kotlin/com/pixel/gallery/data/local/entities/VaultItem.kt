package com.pixel.gallery.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "vault_inventory")
data class VaultItem(
    @PrimaryKey val contentId: Long,
    val vaultPath: String,
    val originalPath: String,
    val entryJson: String // Serialized MediaEntry
)
