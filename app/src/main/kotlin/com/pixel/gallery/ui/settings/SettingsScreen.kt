package com.pixel.gallery.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.ui.unit.dp
import com.pixel.gallery.ui.theme.EmphasizedTypography
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.Tab
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.FolderOff
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.foundation.clickable
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onNavigateToExcludedFolders: () -> Unit,
    onNavigateToLicenses: () -> Unit,
    viewModel: PhotosViewModel = hiltViewModel()
) {
    val materialYou by viewModel.materialYou.collectAsState()
    val startupAtAlbums by viewModel.startupAtAlbums.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        "Settings",
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
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            item {
                SettingsToggleItem(
                    title = "Material You",
                    description = "Use system dynamic colors",
                    icon = Icons.Outlined.Palette,
                    checked = materialYou,
                    onCheckedChange = { viewModel.setMaterialYou(it) }
                )
            }
            item {
                SettingsToggleItem(
                    title = "Start at Albums",
                    description = "Open the albums tab by default",
                    icon = Icons.Outlined.Tab,
                    checked = startupAtAlbums,
                    onCheckedChange = { viewModel.setStartupAtAlbums(it) }
                )
            }
            item {
                SettingsClickItem(
                    title = "Language",
                    description = "System Default",
                    icon = Icons.Outlined.Language,
                    onClick = { /* TODO: Show language picker */ }
                )
            }
            item {
                SettingsClickItem(
                    title = "Excluded Folders",
                    description = "Manage ignored media locations",
                    icon = Icons.Outlined.FolderOff,
                    onClick = onNavigateToExcludedFolders
                )
            }
            item { HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) }
            item {
                SettingsClickItem(
                    title = "About",
                    description = "Pixel Gallery v3.2.1",
                    icon = Icons.Outlined.Info,
                    onClick = onNavigateToLicenses
                )
            }
        }
    }
}

@Composable
fun SettingsToggleItem(
    title: String,
    description: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    ListItem(
        headlineContent = { 
            Text(
                title,
                style = EmphasizedTypography.LabelLarge
            ) 
        },
        supportingContent = { Text(description) },
        leadingContent = { Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
        trailingContent = {
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        }
    )
}

@Composable
fun SettingsClickItem(
    title: String,
    description: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit
) {
    ListItem(
        modifier = Modifier.clickable { onClick() },
        headlineContent = { 
            Text(
                title,
                style = EmphasizedTypography.LabelLarge
            ) 
        },
        supportingContent = { Text(description) },
        leadingContent = { Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary) }
    )
}
