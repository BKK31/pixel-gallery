package com.pixel.gallery.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun DeleteConfirmationDialog(
    itemCount: Int,
    isPermanent: Boolean,
    onConfirm: (bypassTrash: Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    var bypassTrash by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isPermanent || bypassTrash) "Delete Permanently?" else "Move to Recycle Bin?"
            )
        },
        text = {
            Column {
                Text(
                    text = if (isPermanent || bypassTrash) {
                        if (itemCount == 1) {
                            "This item will be deleted permanently and cannot be restored."
                        } else {
                            "These $itemCount items will be deleted permanently and cannot be restored."
                        }
                    } else {
                        if (itemCount == 1) {
                            "Are you sure you want to move this item to the Recycle Bin?"
                        } else {
                            "Are you sure you want to move these $itemCount items to the Recycle Bin?"
                        }
                    }
                )
                if (!isPermanent) {
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { bypassTrash = !bypassTrash }
                            .padding(vertical = 4.dp)
                    ) {
                        Checkbox(
                            checked = bypassTrash,
                            onCheckedChange = { bypassTrash = it }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Delete permanently (bypass Recycle Bin)",
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onConfirm(bypassTrash)
                    onDismiss()
                }
            ) {
                Text(
                    text = if (isPermanent || bypassTrash) "Delete" else "Move to Bin",
                    color = MaterialTheme.colorScheme.error
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
