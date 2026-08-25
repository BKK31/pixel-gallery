package com.pixel.gallery

import android.app.Application
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import com.pixel.gallery.workers.TrashCleanupWorker
import dagger.hilt.android.HiltAndroidApp
import org.osmdroid.config.Configuration as OsmConfiguration
import javax.inject.Inject

@HiltAndroidApp
class PixelGalleryApp : Application(), Configuration.Provider {

    @Inject lateinit var workerFactory: HiltWorkerFactory

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(workerFactory)
            .build()

    override fun onCreate() {
        super.onCreate()

        // OSMdroid Configuration
        OsmConfiguration.getInstance().userAgentValue = packageName

        // Schedule daily trash cleanup
        TrashCleanupWorker.schedule(this)
    }
}
