package com.pixel.gallery.ui.locked

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.pixel.gallery.ui.home.PhotosScreen
import com.pixel.gallery.ui.theme.EmphasizedTypography
import com.pixel.gallery.ui.theme.ExpressiveShapes
import com.pixel.gallery.ui.viewmodel.PhotosViewModel.GridItem

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LockedFolderScreen(
    onBack: () -> Unit,
    onNavigateToViewer: (Long) -> Unit,
    selectedIds: Set<Long> = emptySet(),
    onSelectionChange: (Set<Long>) -> Unit = {},
    onToggleSelection: (Long) -> Unit = {},
    items: List<GridItem> = emptyList()
) {
    val context = LocalContext.current
    var isAuthenticated by remember { mutableStateOf(false) }
    var authError by remember { mutableStateOf<String?>(null) }

    val biometricManager = remember { BiometricManager.from(context) }
    val canAuthenticate = remember {
        biometricManager.canAuthenticate(BIOMETRIC_STRONG or DEVICE_CREDENTIAL)
    }

    fun launchAuth() {
        val executor = ContextCompat.getMainExecutor(context)
        val biometricPrompt = BiometricPrompt(
            context as FragmentActivity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    isAuthenticated = true
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    authError = errString.toString()
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Locked Folder")
            .setSubtitle("Authenticate to view hidden media")
            .setAllowedAuthenticators(BIOMETRIC_STRONG or DEVICE_CREDENTIAL)
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    LaunchedEffect(Unit) {
        if (canAuthenticate != BiometricManager.BIOMETRIC_SUCCESS) {
            // No system lock present or available, bypass as requested
            isAuthenticated = true
        } else {
            launchAuth()
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0),
        topBar = {
            if (selectedIds.isEmpty()) {
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
        }
    ) { innerPadding ->
        if (!isAuthenticated) {
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
                    modifier = Modifier.size(100.dp),
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
                )
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = "Locked Folder is Locked",
                    style = EmphasizedTypography.HeadlineMedium,
                    textAlign = TextAlign.Center
                )
                if (authError != null) {
                    Text(
                        text = authError!!,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
                Spacer(modifier = Modifier.height(32.dp))
                Button(
                    onClick = { launchAuth() },
                    shape = ExpressiveShapes.LargeIncreased
                ) {
                    Text("Unlock with Biometrics")
                }
            }
        } else if (items.isEmpty()) {
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
                    modifier = Modifier.size(100.dp),
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
                )
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = "No Items in Locked Folder",
                    style = EmphasizedTypography.HeadlineMedium,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Move sensitive photos and videos here to hide them from your main gallery and other apps.",
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
                    onToggleSelection = onToggleSelection
                )
            }
        }
    }
}
