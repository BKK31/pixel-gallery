package com.pixel.gallery

import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.pixel.gallery/open_file"
    private val EVENT_CHANNEL = "com.pixel.gallery/open_file_events"
    private var sharedFilePath: String? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFile" -> {
                    result.success(sharedFilePath)
                }
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    val dateAddedSecs = call.argument<Number>("dateAddedSecs")?.toLong()
                    val dateModifiedSecs = call.argument<Number>("dateModifiedSecs")?.toLong()
                    val dateTakenMillis = call.argument<Number>("dateTakenMillis")?.toLong()

                    if (path != null) {
                        android.media.MediaScannerConnection.scanFile(this, arrayOf(path), null) { _, uri ->
                            if (uri != null && (dateAddedSecs != null || dateModifiedSecs != null || dateTakenMillis != null)) {
                                val values = android.content.ContentValues()
                                if (dateAddedSecs != null) values.put(android.provider.MediaStore.MediaColumns.DATE_ADDED, dateAddedSecs)
                                if (dateModifiedSecs != null) values.put(android.provider.MediaStore.MediaColumns.DATE_MODIFIED, dateModifiedSecs)
                                if (dateTakenMillis != null) values.put("datetaken", dateTakenMillis)
                                try {
                                    contentResolver.update(uri, values, null, null)
                                } catch (e: Exception) {
                                    android.util.Log.e("MainActivity", "Error updating scanned file dates: $e")
                                }
                            }
                        }
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                "editFile" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType")
                    if (path != null && mimeType != null) {
                        editFile(path, mimeType)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path or MIME type is null", null)
                    }
                }
                "checkImageHdr" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        result.success(checkImageHdr(path))
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                "getVideoMetadata" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        result.success(getVideoMetadata(path))
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // Window handler for HDR, orientation, etc.
        MethodChannel(messenger, com.pixel.gallery.channel.calls.WindowHandler.CHANNEL).setMethodCallHandler(
            com.pixel.gallery.channel.calls.WindowHandler(this)
        )

        // Aves MediaStore engine channels
        MethodChannel(messenger, com.pixel.gallery.channel.calls.MediaStoreHandler.CHANNEL).setMethodCallHandler(
            com.pixel.gallery.channel.calls.MediaStoreHandler(this)
        )
        app.loup.streams_channel.StreamsChannel(messenger, com.pixel.gallery.channel.streams.MediaStoreStreamHandler.CHANNEL).setStreamHandlerFactory { args ->
            com.pixel.gallery.channel.streams.MediaStoreStreamHandler(this, args)
        }
        app.loup.streams_channel.StreamsChannel(messenger, com.pixel.gallery.channel.streams.ImageByteStreamHandler.CHANNEL).setStreamHandlerFactory { args ->
            com.pixel.gallery.channel.streams.ImageByteStreamHandler(this, args)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (Intent.ACTION_VIEW == intent.action) {
            val uri: Uri? = intent.data
            if (uri != null) {
                val path = copyFileFromUri(uri)
                sharedFilePath = path
                // If Flutter is already running and listening, send the event
                if (path != null) {
                    eventSink?.success(path)
                }
            }
        }
    }

    private fun copyFileFromUri(uri: Uri): String? {
        try {
            val inputStream: InputStream? = contentResolver.openInputStream(uri)
            if (inputStream != null) {
                // Determine file extension (optional, but good for some players)
                val type = contentResolver.getType(uri)
                val extension = when {
                    type?.contains("image") == true -> ".jpg"
                    type?.contains("video") == true -> ".mp4"
                    else -> ".tmp"
                }

                // Create a temp file in cache directory
                val tempFile = File(cacheDir, "shared_file_${UUID.randomUUID()}$extension")
                val outputStream = FileOutputStream(tempFile)

                val buffer = ByteArray(1024)
                var length: Int
                while (inputStream.read(buffer).also { length = it } > 0) {
                    outputStream.write(buffer, 0, length)
                }

                outputStream.close()
                inputStream.close()

                return tempFile.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    companion object {
        const val DOCUMENT_TREE_ACCESS_REQUEST = 1
        const val MEDIA_WRITE_BULK_PERMISSION_REQUEST = 2

        val pendingStorageAccessResultHandlers = HashMap<Int, PendingStorageAccessResultHandler>()
        var pendingScopedStoragePermissionCompleter: java.util.concurrent.CompletableFuture<Boolean>? = null

        fun notifyError(message: String) {
            android.util.Log.e("MainActivity", message)
        }

        private fun onStorageAccessResult(requestCode: Int, uri: Uri?) {
            val handler = pendingStorageAccessResultHandlers.remove(requestCode) ?: return
            if (uri != null) {
                handler.onGranted(uri)
            } else {
                handler.onDenied()
            }
        }
    }

    private fun editFile(path: String, mimeType: String) {
        val file = File(path)
        val uri = androidx.core.content.FileProvider.getUriForFile(
            this,
            "${packageName}.fileprovider",
            file
        )
        val intent = Intent(Intent.ACTION_EDIT).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, "Edit with"))
    }

    private fun getVideoMetadata(path: String): Map<String, Any?> {
        val retriever = MediaMetadataRetriever()
        val metadata = mutableMapOf<String, Any?>()
        try {
            retriever.setDataSource(path)
            metadata["location"] = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_LOCATION)

            // Check for HDR via color transfer (ST2084 = HDR10, HLG = HLG)
            var isHdr = false
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                val colorTransfer = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COLOR_TRANSFER)?.toIntOrNull()
                if (colorTransfer != null) {
                    isHdr = colorTransfer == android.media.MediaFormat.COLOR_TRANSFER_ST2084 ||
                            colorTransfer == android.media.MediaFormat.COLOR_TRANSFER_HLG
                }
            }
            metadata["isHdr"] = isHdr
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error extracting video metadata: $e")
        } finally {
            retriever.release()
        }
        return metadata
    }

    /**
     * Check if an image file has HDR gain map metadata.
     * Uses ExifInterface to look for XMP HDR gain map properties (pin to pin with Aves).
     */
    private fun checkImageHdr(path: String): Boolean {
        try {
            val file = java.io.File(path)
            if (!file.exists()) return false

            val exif = androidx.exifinterface.media.ExifInterface(path)
            val xmpData = exif.getAttribute("Xmp")
            if (xmpData != null) {
                // Check for standard HDR gain map namespaces as used in Aves
                if (xmpData.contains("http://ns.adobe.com/hdr-gain-map/1.0/") ||
                    xmpData.contains("http://ns.apple.com/HDRGainMap/1.0/") ||
                    xmpData.contains("hdrgm:Version") ||
                    xmpData.contains("HDRGainMapVersion") ||
                    xmpData.contains("http://ns.google.com/photos/1.0/ultrahighdynamicrange/")) {
                    return true
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking image HDR: $e")
        }
        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            DOCUMENT_TREE_ACCESS_REQUEST -> onStorageAccessResult(requestCode, data?.data)
            MEDIA_WRITE_BULK_PERMISSION_REQUEST -> pendingScopedStoragePermissionCompleter?.complete(resultCode == RESULT_OK)
        }
    }
}

data class PendingStorageAccessResultHandler(val path: String?, val onGranted: (uri: Uri) -> Unit, val onDenied: () -> Unit)
