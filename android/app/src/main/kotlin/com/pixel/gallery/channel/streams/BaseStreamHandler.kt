package com.pixel.gallery.channel.streams

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.pixel.gallery.utils.MemoryUtils
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import java.io.InputStream

abstract class BaseStreamHandler : EventChannel.StreamHandler {
    val ioScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private var eventSink: EventChannel.EventSink? = null
    private var handler: Handler? = null

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        this.eventSink = eventSink
        handler = Handler(Looper.getMainLooper())
        onCall(arguments)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        handler = null
    }

    open fun success(event: Any?) {
        handler?.post {
            try {
                eventSink?.success(event)
            } catch (e: Exception) {
                Log.w(logTag, "failed to use event sink", e)
            }
        }
    }

    open fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        handler?.post {
            try {
                eventSink?.error(errorCode, errorMessage, errorDetails)
            } catch (e: Exception) {
                Log.w(logTag, "failed to use event sink", e)
            }
        }
    }

    open fun endOfStream() {
        handler?.post {
            try {
                eventSink?.endOfStream()
            } catch (e: Exception) {
                Log.w(logTag, "failed to use event sink", e)
            }
        }
    }

    fun safe(function: () -> Unit, closeStream: Boolean = true) {
        try {
            function()
        } catch (e: Exception) {
            error("safe-exception", e.message, e.stackTraceToString())
        }
        if (closeStream) {
            endOfStream()
        }
    }

    suspend fun safeSuspend(function: suspend () -> Unit, closeStream: Boolean = true) {
        try {
            function()
        } catch (e: Exception) {
            error("safe-exception", e.message, e.stackTraceToString())
        }
        if (closeStream) {
            endOfStream()
        }
    }

    abstract val logTag: String

    open fun onCall(args: Any?) {
        // nothing by default
    }

    companion object {
        const val BUFFER_SIZE = 1 shl 18 // 256kB
    }
}
