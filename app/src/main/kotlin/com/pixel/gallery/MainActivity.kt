package com.pixel.gallery

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.pixel.gallery.ui.MainScaffold
import com.pixel.gallery.ui.theme.PixelGalleryTheme
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val viewModel: PhotosViewModel by viewModels()

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.entries.all { it.value }
        if (allGranted) {
            viewModel.refresh()
        }
    }

    private val intentSenderLauncher = registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            viewModel.refresh()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        _intentSenderLauncher = intentSenderLauncher
        
        enableEdgeToEdge()
        
        setContent {
            PixelGalleryTheme {
                Surface(
                    modifier = Modifier.fillMaxSize()
                ) {
                    MainScaffold()
                }
            }
        }
        
        checkPermissions()
        handleIntent(intent)
    }

    private fun checkPermissions() {
        // Request MANAGE_EXTERNAL_STORAGE for Android 11+ to avoid per-file prompts
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                        data = Uri.parse("package:${packageName}")
                    }
                    startActivity(intent)
                } catch (e: Exception) {
                    val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                    startActivity(intent)
                }
            }
        }

        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                android.Manifest.permission.READ_MEDIA_IMAGES,
                android.Manifest.permission.READ_MEDIA_VIDEO
            )
        } else {
            arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE)
        }

        val needsPermission = permissions.any {
            checkSelfPermission(it) != android.content.pm.PackageManager.PERMISSION_GRANTED
        }

        if (needsPermission) {
            requestPermissionLauncher.launch(permissions)
        } else {
            viewModel.refresh()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Intent handling logic for direct file opening will be implemented later
    }

    companion object {
        const val DOCUMENT_TREE_ACCESS_REQUEST = 1
        const val MEDIA_WRITE_BULK_PERMISSION_REQUEST = 2

        private var _intentSenderLauncher: ActivityResultLauncher<IntentSenderRequest>? = null
        
        fun launchIntentSender(request: IntentSenderRequest) {
            _intentSenderLauncher?.launch(request)
        }

        val pendingStorageAccessResultHandlers = HashMap<Int, PendingStorageAccessResultHandler>()
        var pendingScopedStoragePermissionCompleter: java.util.concurrent.CompletableFuture<Boolean>? = null

        fun notifyError(message: String) {
            android.util.Log.e("MainActivity", message)
        }
    }
}

data class PendingStorageAccessResultHandler(val path: String?, val onGranted: (android.net.Uri) -> Unit, val onDenied: () -> Unit)
