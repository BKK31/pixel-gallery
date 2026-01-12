package com.pixel.gallery

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
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
                    if (path != null) {
                        android.media.MediaScannerConnection.scanFile(this, arrayOf(path), null) { _, _ -> }
                        result.success(true)
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            DOCUMENT_TREE_ACCESS_REQUEST -> onStorageAccessResult(requestCode, data?.data)
            MEDIA_WRITE_BULK_PERMISSION_REQUEST -> pendingScopedStoragePermissionCompleter?.complete(resultCode == RESULT_OK)
        }
    }
}

data class PendingStorageAccessResultHandler(val path: String?, val onGranted: (uri: Uri) -> Unit, val onDenied: () -> Unit)
