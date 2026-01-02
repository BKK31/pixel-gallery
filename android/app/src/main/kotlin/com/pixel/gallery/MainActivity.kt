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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInitialFile") {
                result.success(sharedFilePath)
            } else {
                result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // If we have a pending file that hasn't been handled by the initial check, sending it here might be duplicate
                    // but usually safe. For now, rely on MethodChannel for initial and this for updates.
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
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
}
