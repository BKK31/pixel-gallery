package com.pixel.gallery

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import org.osmdroid.config.Configuration

@HiltAndroidApp
class PixelGalleryApp : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // OSMdroid Configuration
        Configuration.getInstance().userAgentValue = packageName
    }
}
