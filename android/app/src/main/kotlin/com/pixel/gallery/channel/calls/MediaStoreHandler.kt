package com.pixel.gallery.channel.calls

import android.content.Context
import com.pixel.gallery.model.provider.MediaStoreImageProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class MediaStoreHandler(private val context: Context) : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkObsoleteContentIds" -> checkObsoleteContentIds(call, result)
            "checkObsoletePaths" -> checkObsoletePaths(call, result)
            "getChangedUris" -> getChangedUris(call, result)
            else -> result.notImplemented()
        }
    }

    private fun checkObsoleteContentIds(call: MethodCall, result: MethodChannel.Result) {
        val knownContentIds = call.argument<List<Number>>("knownContentIds")
        if (knownContentIds == null) {
            result.error("checkObsoleteContentIds-args", "missing arguments", null)
            return
        }
        result.success(MediaStoreImageProvider().checkObsoleteContentIds(context, knownContentIds.map { it.toLong() }))
    }

    private fun checkObsoletePaths(call: MethodCall, result: MethodChannel.Result) {
        val knownPathByIdRaw = call.argument<Map<String, String>>("knownPathById")
        if (knownPathByIdRaw == null) {
            result.error("checkObsoletePaths-args", "missing arguments", null)
            return
        }
        val knownPathById = knownPathByIdRaw.mapKeys { it.key.toLongOrNull() }
        result.success(MediaStoreImageProvider().checkObsoletePaths(context, knownPathById))
    }

    private fun getChangedUris(call: MethodCall, result: MethodChannel.Result) {
        val sinceGeneration = call.argument<Int>("sinceGeneration")
        if (sinceGeneration == null) {
            result.error("getChangedUris-args", "missing arguments", null)
            return
        }
        result.success(MediaStoreImageProvider().getChangedUris(context, sinceGeneration))
    }

    companion object {
        const val CHANNEL = "com.pixel.gallery/mediastore"
    }
}
