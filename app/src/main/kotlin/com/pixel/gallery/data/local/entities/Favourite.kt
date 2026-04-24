package com.pixel.gallery.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "favourites")
data class Favourite(
    @PrimaryKey val id: Long // contentId
)
