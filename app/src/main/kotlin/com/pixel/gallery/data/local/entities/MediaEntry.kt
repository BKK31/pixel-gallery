package com.pixel.gallery.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "media_entries")
data class MediaEntry(
    @PrimaryKey val contentId: Long,
    val uri: String,
    val path: String?,
    val sourceMimeType: String,
    val width: Int?,
    val height: Int?,
    val sourceRotationDegrees: Int,
    val sizeBytes: Long?,
    val dateAddedSecs: Long?,
    val dateModifiedMillis: Long?,
    val sourceDateTakenMillis: Long?,
    val durationMillis: Long?
)
