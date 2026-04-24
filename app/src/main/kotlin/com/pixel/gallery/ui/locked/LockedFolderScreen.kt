package com.pixel.gallery.ui.locked

import androidx.compose.foundation.layout.*
import androidx.compose.ui.unit.dp
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.theme.ExpressiveShapes
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LockedFolderScreen(onBack: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        "Locked Folder",
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(32.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Outlined.Lock,
                contentDescription = null,
                modifier = Modifier.size(120.dp),
                tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = "Secure Your Media",
                style = EmphasizedTypography.HeadlineMedium,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Move sensitive photos and videos to this folder. They will be protected by your device screen lock or biometrics.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(48.dp))
            Button(
                onClick = { /* TODO: Trigger Biometrics */ },
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(16.dp),
                shape = ExpressiveShapes.LargeIncreased
            ) {
                Text(
                    "Unlock folder",
                    style = EmphasizedTypography.LabelLarge
                )
            }
        }
    }
}
