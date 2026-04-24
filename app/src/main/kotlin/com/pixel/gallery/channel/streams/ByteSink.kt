package com.pixel.gallery.channel.streams

import java.io.InputStream

interface ByteSink {
    fun success(result: Any?)
    fun error(errorCode: String, errorMessage: String?, errorDetails: Any?)
    fun streamBytes(inputStream: InputStream)
}
