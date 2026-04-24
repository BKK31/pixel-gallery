package com.pixel.gallery.model.provider

import android.content.Context
import android.net.Uri
import com.pixel.gallery.model.FieldMap
import com.pixel.gallery.utils.LogUtils

abstract class ImageProvider {
    open fun fetchSingle(context: Context, uri: Uri, sourceMimeType: String?, allowUnsized: Boolean, callback: ImageOpCallback) {
        callback.onFailure(UnsupportedOperationException("`fetchSingle` is not supported by this image provider"))
    }

    interface ImageOpCallback {
        fun onSuccess(fields: FieldMap)
        fun onFailure(throwable: Throwable)
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ImageProvider>()
    }
}
