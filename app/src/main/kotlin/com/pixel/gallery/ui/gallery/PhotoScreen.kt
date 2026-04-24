package com.pixel.gallery.ui.gallery

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.viewmodel.PhotosViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PhotoScreen(
    albumName: String,
    onBack: () -> Unit,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onToggleSelection: (Long) -> Unit = {},
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val allPhotos by viewModel.photos.collectAsState()
    val albumPhotos = remember(allPhotos, albumName) {
        allPhotos.filter { 
            val file = java.io.File(it.path)
            file.parentFile?.name == albumName
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0),
        topBar = {
            if (selectedIds.isEmpty()) {
                TopAppBar(
                    title = { 
                        Column {
                            Text(
                                albumName,
                                style = EmphasizedTypography.TitleLarge
                            )
                            Text(
                                "${albumPhotos.size} items",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    },
                    actions = {
                        IconButton(onClick = { /* TODO: Sort/Filter */ }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "More")
                        }
                    }
                )
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding)) {
            PhotosScreen(
                photos = albumPhotos,
                onNavigateToViewer = onNavigateToViewer,
                selectedIds = selectedIds,
                onToggleSelection = onToggleSelection,
                columns = 4 // Keep the album view denser
            )
        }
    }
}
