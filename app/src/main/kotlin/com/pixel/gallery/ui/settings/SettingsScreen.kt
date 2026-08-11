package com.pixel.gallery.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.ui.unit.dp
import com.pixel.gallery.ui.theme.EmphasizedTypography
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.Tab
import androidx.compose.material.icons.outlined.FolderOff
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.DeleteForever
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.foundation.clickable
import androidx.hilt.navigation.compose.hiltViewModel
import com.pixel.gallery.ui.viewmodel.PhotosViewModel
import androidx.compose.ui.res.stringResource
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.pixel.gallery.R

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
    val confirmTrash by viewModel.confirmTrash.collectAsState()
    val confirmDelete by viewModel.confirmDelete.collectAsState()
    var showLanguageDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        stringResource(R.string.settings),
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
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            item {
                SettingsToggleItem(
                    title = stringResource(R.string.material_you),
                    description = stringResource(R.string.material_you_desc),
                    icon = Icons.Outlined.Palette,
                    checked = materialYou,
                    onCheckedChange = { viewModel.setMaterialYou(it) }
                )
            }
            item {
                SettingsToggleItem(
                    title = stringResource(R.string.start_at_albums),
                    description = stringResource(R.string.start_at_albums_desc),
                    icon = Icons.Outlined.Tab,
                    checked = startupAtAlbums,
                    onCheckedChange = { viewModel.setStartupAtAlbums(it) }
                )
            }
            item {
                SettingsClickItem(
                    title = stringResource(R.string.language),
                    description = stringResource(R.string.language_desc),
                    icon = Icons.Outlined.Translate,
                    onClick = { showLanguageDialog = true }
                )
            }
            item {
                SettingsClickItem(
                    title = stringResource(R.string.excluded_folders),
                    description = stringResource(R.string.excluded_folders_desc),
                    icon = Icons.Outlined.FolderOff,
                    onClick = onNavigateToExcludedFolders
                )
            }
            item { HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) }
            item {
                SettingsToggleItem(
                    title = stringResource(R.string.confirm_trash),
                    description = stringResource(R.string.confirm_trash_desc),
                    icon = Icons.Outlined.DeleteSweep,
                    checked = confirmTrash,
                    onCheckedChange = { viewModel.setConfirmTrash(it) }
                )
            }
            item {
                SettingsToggleItem(
                    title = stringResource(R.string.confirm_delete_permanently),
                    description = stringResource(R.string.confirm_delete_permanently_desc),
                    icon = Icons.Outlined.DeleteForever,
                    checked = confirmDelete,
                    onCheckedChange = { viewModel.setConfirmDelete(it) }
                )
            }
            item { HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) }
            item {
                SettingsClickItem(
                    title = stringResource(R.string.about_title),
                    description = stringResource(R.string.about_desc),
                    icon = Icons.Outlined.Info,
                    onClick = onNavigateToLicenses
                )
            }
        }
    }

    if (showLanguageDialog) {
        AlertDialog(
            onDismissRequest = { showLanguageDialog = false },
            title = { Text(stringResource(R.string.select_language)) },
            text = {
                Column {
                    val currentLocale = AppCompatDelegate.getApplicationLocales().get(0)?.language ?: "en"
                    
                    ListItem(
                        modifier = Modifier.clickable {
                            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("en"))
                            showLanguageDialog = false
                        },
                        headlineContent = { Text(stringResource(R.string.language_english)) },
                        trailingContent = { if (currentLocale == "en") Icon(Icons.Default.Check, null) }
                    )
                    ListItem(
                        modifier = Modifier.clickable {
                            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("kn"))
                            showLanguageDialog = false
                        },
                        headlineContent = { Text(stringResource(R.string.language_kannada)) },
                        trailingContent = { if (currentLocale == "kn") Icon(Icons.Default.Check, null) }
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = { showLanguageDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
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
