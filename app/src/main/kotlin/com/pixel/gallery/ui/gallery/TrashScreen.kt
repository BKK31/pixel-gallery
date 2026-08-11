package com.pixel.gallery.ui.gallery

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.ui.res.stringResource
import com.pixel.gallery.R
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel.GridItem

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrashScreen(
    onBack: () -> Unit,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onSelectionChange: (Set<Long>) -> Unit = {},
    onToggleSelection: (Long) -> Unit = {},
    items: List<GridItem> = emptyList(),
    gridState: LazyGridState = rememberLazyGridState(),
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val gridColumns by viewModel.gridColumns.collectAsState()
    var showEmptyConfirmDialog by remember { mutableStateOf(false) }

    Scaffold(
        contentWindowInsets = WindowInsets(0),
        topBar = {
            if (selectedIds.isEmpty()) {
                TopAppBar(
                    title = { 
                        Text(
                            stringResource(R.string.recycle_bin),
                            style = EmphasizedTypography.TitleLarge
                        ) 
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.Default.ChevronLeft, contentDescription = stringResource(R.string.back))
                        }
                    },
                    actions = {
                        if (items.isNotEmpty()) {
                            TextButton(onClick = { showEmptyConfirmDialog = true }) {
                                Text(stringResource(R.string.empty_action), color = MaterialTheme.colorScheme.error)
                            }
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
                    imageVector = Icons.Outlined.DeleteOutline,
                    contentDescription = null,
                    modifier = Modifier.size(100.dp),
                    tint = MaterialTheme.colorScheme.error.copy(alpha = 0.4f)
                )
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = stringResource(R.string.bin_empty),
                    style = EmphasizedTypography.HeadlineMedium,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.bin_empty_text),
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

        if (showEmptyConfirmDialog) {
            AlertDialog(
                onDismissRequest = { showEmptyConfirmDialog = false },
                title = { Text(stringResource(R.string.empty_bin_title)) },
                text = { Text(stringResource(R.string.empty_bin_desc)) },
                confirmButton = {
                    TextButton(
                        onClick = {
                            val uris = items.filterIsInstance<GridItem.Photo>().map { it.entry.uri }
                            viewModel.deleteMediaBulk(uris)
                            showEmptyConfirmDialog = false
                        }
                    ) {
                        Text(stringResource(R.string.empty_action), color = MaterialTheme.colorScheme.error)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showEmptyConfirmDialog = false }) {
                        Text(stringResource(R.string.cancel))
                    }
                }
            )
        }
    }
}
