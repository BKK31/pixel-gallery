package com.pixel.gallery.channel.calls

import android.app.Activity
import android.content.Context
import android.content.pm.ActivityInfo
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.OrientationEventListener
import android.view.WindowManager
import com.pixel.gallery.utils.LogUtils
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Handles window-related method channel calls.
 * Re-implemented pin-to-pin with Aves: ActivityWindowHandler
 */
class WindowHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "supportsHdr" -> supportsHdr(call, result)
            "setColorMode" -> setColorMode(call, result)
            "isRotationLocked" -> isRotationLocked(call, result)
            "getOrientation" -> getOrientation(call, result)
            "requestOrientation" -> requestOrientation(call, result)
            "getSensorOrientation" -> getSensorOrientation(call, result)
            else -> result.notImplemented()
        }
    }

    private fun supportsHdr(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        result.success(
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                activity.resources.configuration.isScreenHdr
        )
    }

    private fun setColorMode(call: MethodCall, result: MethodChannel.Result) {
        val wideColorGamut = call.argument<Boolean>("wideColorGamut")
        val hdr = call.argument<Boolean>("hdr")
        if (wideColorGamut == null || hdr == null) {
            result.error("setColorMode-args", "missing arguments", null)
            return
        }

        // Pin-to-pin with Aves: only set the color mode.
        // No manual screen brightness overrides, which ensures native HDR highlights 
        // boost naturally as intended by the device manufacturer.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.window.colorMode = if (hdr) {
                ActivityInfo.COLOR_MODE_HDR
            } else if (wideColorGamut) {
                ActivityInfo.COLOR_MODE_WIDE_COLOR_GAMUT
            } else {
                ActivityInfo.COLOR_MODE_DEFAULT
            }
        }
        result.success(null)
    }

    private fun isRotationLocked(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        var locked = false
        try {
            locked = Settings.System.getInt(
                activity.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION
            ) == 0
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to get settings with error=${e.message}", null)
        }
        result.success(locked)
    }

    // display orientation in degrees
    private fun getOrientation(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        val displayRotation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.rotation ?: 0
        } else {
            val windowService = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            @Suppress("deprecation")
            windowService.defaultDisplay.rotation
        }
        result.success(displayRotation * 90)
    }

    private fun requestOrientation(call: MethodCall, result: MethodChannel.Result) {
        val orientation = call.argument<Int>("orientation")
        if (orientation == null) {
            result.error("requestOrientation-args", "missing arguments", null)
            return
        }
        activity.requestedOrientation = orientation
        result.success(true)
    }

    /**
     * Physical orientation detection (also from Aves reference).
     */
    private fun getSensorOrientation(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        val resolved = AtomicBoolean(false)

        val listener = object : OrientationEventListener(activity) {
            override fun onOrientationChanged(degrees: Int) {
                if (!resolved.compareAndSet(false, true)) return
                this.disable()

                if (degrees == ORIENTATION_UNKNOWN) {
                    result.success(-1)
                    return
                }

                // Map degrees to orientation constants (Aves style)
                val orientation = when {
                    degrees in 316..360 || degrees in 0..45 -> SENSOR_PORTRAIT
                    degrees in 46..135 -> SENSOR_REVERSE_LANDSCAPE
                    degrees in 136..225 -> SENSOR_REVERSE_PORTRAIT
                    degrees in 226..315 -> SENSOR_LANDSCAPE
                    else -> -1
                }
                result.success(orientation)
            }
        }

        if (listener.canDetectOrientation()) {
            listener.enable()
            activity.window.decorView.postDelayed({
                if (resolved.compareAndSet(false, true)) {
                    listener.disable()
                    result.success(-1)
                }
            }, 500)
        } else {
            result.success(-1)
        }
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<WindowHandler>()
        const val CHANNEL = "com.pixel.gallery/window"

        // Sensor orientation return values
        const val SENSOR_PORTRAIT = 0
        const val SENSOR_REVERSE_PORTRAIT = 1
        const val SENSOR_LANDSCAPE = 2
        const val SENSOR_REVERSE_LANDSCAPE = 3
    }
}
