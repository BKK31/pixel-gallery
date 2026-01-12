package com.pixel.gallery.channel.streams

import android.content.Context
import com.pixel.gallery.model.provider.MediaStoreImageProvider
import com.pixel.gallery.utils.LogUtils
import kotlinx.coroutines.launch

class MediaStoreStreamHandler(private val context: Context, arguments: Any?) : BaseStreamHandler() {
    private var knownEntries: Map<Long?, Long?>? = null
    private var directory: String? = null

    init {
        if (arguments is Map<*, *>) {
            knownEntries = (arguments["knownEntries"] as? Map<*, *>?)?.map { (it.key as? Number)?.toLong() to (it.value as? Number)?.toLong() }?.toMap()
            directory = arguments["directory"] as String?
        }
    }

    override val logTag = LOG_TAG

    override fun onCall(args: Any?) {
        ioScope.launch { safe(::fetchAll) }
    }

    private fun fetchAll() {
        val provider = MediaStoreImageProvider()
        val total = provider.countAll(context, null, null)
        success(mapOf("count" to total))

        val batch = ArrayList<com.pixel.gallery.model.FieldMap>()
        provider.fetchAll(context, knownEntries ?: emptyMap(), directory) { entry ->
            batch.add(entry)
            if (batch.size >= 100) {
                success(ArrayList(batch))
                batch.clear()
            }
        }
        if (batch.isNotEmpty()) {
            success(batch)
        }
        endOfStream()
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<MediaStoreStreamHandler>()
        const val CHANNEL = "com.pixel.gallery/mediastore_stream"
    }
}
