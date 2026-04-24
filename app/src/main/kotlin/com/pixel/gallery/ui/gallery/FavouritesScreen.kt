package com.pixel.gallery.ui.gallery

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pixel.gallery.ui.home.PhotoTilePlaceholder
import com.pixel.gallery.ui.theme.EmphasizedTypography

import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.viewmodel.PhotosViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavouritesScreen(
    onBack: () -> Unit,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onToggleSelection: (Long) -> Unit = {},
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val favourites by viewModel.favourites.collectAsState()

    Scaffold(
        contentWindowInsets = WindowInsets(0),
        topBar = {
            if (selectedIds.isEmpty()) {
                TopAppBar(
                    title = { 
                        Text(
                            "Favourites",
                            style = EmphasizedTypography.TitleLarge
                        ) 
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
            }
        }
    ) { innerPadding ->
        if (favourites.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(32.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Outlined.StarOutline,
                    contentDescription = null,
                    modifier = Modifier.size(100.dp),
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
                )
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = "No Favourites Yet",
                    style = EmphasizedTypography.HeadlineMedium,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Photos and videos you mark as favourites will appear here.",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        } else {
            Box(modifier = Modifier.padding(innerPadding)) {
                PhotosScreen(
                    photos = favourites,
                    onNavigateToViewer = onNavigateToViewer,
                    selectedIds = selectedIds,
                    onToggleSelection = onToggleSelection
                )
            }
        }
    }
}
