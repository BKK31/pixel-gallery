package com.pixel.gallery.services

import android.content.Context
import androidx.exifinterface.media.ExifInterface
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.FileOutputStream
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

    /**
     * Checks if the given JPEG is an Android Motion Photo 1.0.
     * Extracts the embedded MP4 to a temporary file and returns it.
     * Memory-efficient version using streams.
     */
    fun extractMotionVideo(path: String): File? {
        val file = File(path)
        if (!file.exists()) return null
        
        try {
            val exif = ExifInterface(path)
            val xmp = exif.getAttribute(ExifInterface.TAG_XMP)
            if (xmp == null || !xmp.contains("MotionPhoto")) return null
            
            // Motion photos usually have the video at the end.
            // We search for the "ftyp" marker by reading from the end in chunks.
            val marker = "ftyp".toByteArray()
            val buffer = ByteArray(8192)
            var videoOffset = -1L
            
            file.inputStream().use { fis ->
                val fileSize = file.length()
                // Scan the last 1MB or so (most motion videos are 100kb-1MB)
                val scanLimit = Math.min(fileSize, 2048 * 1024L)
                val startPos = fileSize - scanLimit
                fis.skip(startPos)
                
                var totalRead = 0L
                while (totalRead < scanLimit) {
                    val read = fis.read(buffer)
                    if (read == -1) break
                    
                    // Simple search for marker
                    for (i in 0 until read - 4) {
                        if (buffer[i] == marker[0] && buffer[i+1] == marker[1] && 
                            buffer[i+2] == marker[2] && buffer[i+3] == marker[3]) {
                            videoOffset = startPos + totalRead + i - 4
                        }
                    }
                    totalRead += read
                }
            }
            
            if (videoOffset > 0) {
                // Use a unique temp file to avoid crashes when swiping quickly
                val tempVideo = File.createTempFile("motion_", ".mp4", context.cacheDir)
                file.inputStream().use { fis ->
                    fis.skip(videoOffset)
                    tempVideo.outputStream().use { fos ->
                        fis.copyTo(fos)
                    }
                }
                return tempVideo
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    /**
     * Detects if a JPEG contains Ultra HDR Gainmap metadata (XMP).
     * Includes namespaces for Adobe, Apple, and Google UltraHDR (parity with main branch).
     */
    fun isUltraHdr(path: String): Boolean {
        if (!path.endsWith(".jpg", ignoreCase = true) && !path.endsWith(".jpeg", ignoreCase = true)) return false
        return try {
            val exif = ExifInterface(path)
            val xmp = exif.getAttribute(ExifInterface.TAG_XMP)
            xmp != null && (
                xmp.contains("http://ns.adobe.com/hdr-gain-map/1.0/") ||
                xmp.contains("http://ns.apple.com/HDRGainMap/1.0/") ||
                xmp.contains("hdrgm:Version") ||
                xmp.contains("HDRGainMapVersion") ||
                xmp.contains("http://ns.google.com/photos/1.0/ultrahighdynamicrange/") ||
                xmp.contains("HasGainMap=\"True\"")
            )
        } catch (e: Exception) {
            false
        }
    }
}
