package com.pixel.gallery.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "media_metadata")
data class MetadataEntry(
    @PrimaryKey val id: Long,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val make: String? = null,
    val model: String? = null,
    val xmpSubjects: String? = null,
    val xmpTitle: String? = null,
    val rating: Int? = null,
    val isHdr: Boolean = false
)
