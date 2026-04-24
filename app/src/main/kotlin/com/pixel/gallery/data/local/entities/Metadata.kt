package com.pixel.gallery.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "metadata")
data class Metadata(
    @PrimaryKey val id: Long, // contentId from MediaEntry
    val latitude: Double?,
    val longitude: Double?,
    val make: String?,
    val model: String?,
    val xmpSubjects: String?,
    val xmpTitle: String?,
    val rating: Int?,
    val isHdr: Boolean = false
)
