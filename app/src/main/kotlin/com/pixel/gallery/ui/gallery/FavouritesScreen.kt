package com.pixel.gallery.ui.gallery

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pixel.gallery.ui.theme.EmphasizedTypography
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel.GridItem

import androidx.compose.ui.res.stringResource
import com.pixel.gallery.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavouritesScreen(
    onBack: () -> Unit,
    items: List<GridItem>,
    selectedIds: Set<Long>,
    onSelectionChange: (Set<Long>) -> Unit,
    onToggleSelection: (Long) -> Unit,
    onNavigateToViewer: (Long) -> Unit,
    gridState: LazyGridState = rememberLazyGridState(),
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val gridColumns by viewModel.gridColumns.collectAsState()

    Scaffold(
        contentWindowInsets = WindowInsets(0),
        topBar = {
            if (selectedIds.isEmpty()) {
                TopAppBar(
                    title = { 
                        Text(
                            stringResource(R.string.favourites),
                            style = EmphasizedTypography.TitleLarge
                        ) 
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.Default.ChevronLeft, contentDescription = stringResource(R.string.back))
                        }
                    }
                )
            }
        }
    ) { innerPadding ->
        if (items.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(32.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Outlined.FavoriteBorder,
                    contentDescription = null,
                    modifier = Modifier.size(100.dp),
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
                )
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = stringResource(R.string.no_favourites),
                    style = EmphasizedTypography.HeadlineMedium,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.favourites_empty_text),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        } else {
            Box(modifier = Modifier.padding(innerPadding)) {
                PhotosScreen(
                    items = items,
                    onNavigateToViewer = onNavigateToViewer,
                    selectedIds = selectedIds,
                    onSelectionChange = onSelectionChange,
                    onToggleSelection = onToggleSelection,
                    columns = gridColumns,
                    onColumnsChange = { viewModel.setGridColumns(it) },
                    state = gridState
                )
            }
        }
    }
}
