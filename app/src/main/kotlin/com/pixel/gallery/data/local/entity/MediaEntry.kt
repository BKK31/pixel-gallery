package com.pixel.gallery.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "media_entries")
data class MediaEntry(
    @PrimaryKey val contentId: Long,
    val uri: String,
    val path: String,
    val sourceMimeType: String,
    val width: Int,
    val height: Int,
    val sourceRotationDegrees: Int,
    val sizeBytes: Long,
    val dateAddedSecs: Long,
    val dateModifiedMillis: Long,
    val sourceDateTakenMillis: Long? = null,
    val durationMillis: Long? = null,
    val isTrashed: Boolean = false,
    val bestTimestamp: Long = 0L
)
