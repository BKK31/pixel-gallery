package com.pixel.gallery.ui.gallery

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.outlined.FolderOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel.GridItem
import androidx.compose.material.icons.outlined.VisibilityOff

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PhotoScreen(
    albumName: String,
    onBack: () -> Unit,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onToggleSelection: (Long) -> Unit = {},
    gridState: LazyGridState = rememberLazyGridState(),
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val allPhotos by viewModel.allPhotos.collectAsState()
    val albumItems = remember(allPhotos, albumName) {
        val filtered = allPhotos.filter { 
            val file = java.io.File(it.path)
            file.parentFile?.name == albumName
        }
        viewModel.groupMedia(filtered)
    }

    val photoCount = remember(albumItems) {
        albumItems.count { it is GridItem.Photo }
    }

    var showMenu by remember { mutableStateOf(false) }
    val albumPath = remember(allPhotos, albumName) {
        allPhotos.find { 
            java.io.File(it.path).parentFile?.name == albumName 
        }?.let { java.io.File(it.path).parent } ?: ""
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
                                "$photoCount items",
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
                        IconButton(onClick = { showMenu = true }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "More")
                        }
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Hide Album") },
                                onClick = {
                                    showMenu = false
                                    if (albumPath.isNotEmpty()) {
                                        viewModel.addHiddenFolder(albumPath)
                                        onBack()
                                    }
                                },
                                leadingIcon = { Icon(Icons.Outlined.VisibilityOff, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Exclude Album") },
                                onClick = {
                                    showMenu = false
                                    if (albumPath.isNotEmpty()) {
                                        viewModel.addExcludedFolder(albumPath)
                                        onBack()
                                    }
                                },
                                leadingIcon = { Icon(Icons.Outlined.FolderOff, contentDescription = null) }
                            )
                        }
                    }
                )
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding)) {
            PhotosScreen(
                items = albumItems,
                onNavigateToViewer = onNavigateToViewer,
                selectedIds = selectedIds,
                onToggleSelection = onToggleSelection,
                columns = 4, // Keep the album view denser
                state = gridState
            )
        }
    }
}
