package com.pixel.gallery.services

import android.content.Context
import androidx.exifinterface.media.ExifInterface
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MetadataService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    fun getMetadata(path: String): Map<String, String> {
        return try {
            val exif = ExifInterface(path)
            mapOf(
                "Make" to (exif.getAttribute(ExifInterface.TAG_MAKE) ?: "Unknown"),
                "Model" to (exif.getAttribute(ExifInterface.TAG_MODEL) ?: "Unknown"),
                "Aperture" to (exif.getAttribute(ExifInterface.TAG_F_NUMBER) ?: "Unknown"),
                "Exposure Time" to (exif.getAttribute(ExifInterface.TAG_EXPOSURE_TIME) ?: "Unknown"),
                "ISO" to (exif.getAttribute(ExifInterface.TAG_ISO_SPEED_RATINGS) ?: "Unknown"),
                "Focal Length" to (exif.getAttribute(ExifInterface.TAG_FOCAL_LENGTH) ?: "Unknown"),
                "Date Taken" to (exif.getAttribute(ExifInterface.TAG_DATETIME) ?: "Unknown")
            )
        } catch (e: Exception) {
            emptyMap()
        }
    }
    
    fun getCoordinates(path: String): Pair<Double, Double>? {
        return try {
            val exif = ExifInterface(path)
            val latLong = FloatArray(2)
            if (exif.getLatLong(latLong)) {
                latLong[0].toDouble() to latLong[1].toDouble()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
