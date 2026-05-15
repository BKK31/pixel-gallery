package com.pixel.gallery.widget

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.util.Size
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.appwidget.AppWidgetManager
import com.pixel.gallery.R
import com.pixel.gallery.data.repository.SettingsRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import javax.inject.Inject

@AndroidEntryPoint
class SlideshowWidgetService : RemoteViewsService() {

    @Inject
    lateinit var settingsRepository: SettingsRepository

    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return SlideshowRemoteViewsFactory(this.applicationContext, intent, settingsRepository)
    }
}

class SlideshowRemoteViewsFactory(
    private val context: Context,
    intent: Intent,
    private val settingsRepository: SettingsRepository
) : RemoteViewsService.RemoteViewsFactory {

    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )
    private var uris: List<String> = emptyList()

    override fun onCreate() {
        // Init if needed
    }

    override fun onDataSetChanged() {
        uris = runBlocking {
            settingsRepository.getWidgetUris(appWidgetId).first().toList()
        }
    }

    override fun onDestroy() {
        // Cleanup if needed
    }

    override fun getCount(): Int = uris.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_slideshow_item)

        if (position < uris.size) {
            val uriString = uris[position]
            try {
                val uri = Uri.parse(uriString)
                val bitmap: Bitmap = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    context.contentResolver.loadThumbnail(uri, Size(800, 800), null)
                } else {
                    @Suppress("DEPRECATION")
                    android.provider.MediaStore.Images.Media.getBitmap(context.contentResolver, uri)
                }
                views.setImageViewBitmap(R.id.widget_image, bitmap)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
