package com.pixel.gallery.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

import androidx.compose.ui.res.stringResource
import com.pixel.gallery.R

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
                text = if (isPermanent || bypassTrash) {
                    stringResource(R.string.delete_permanently_title)
                } else {
                    stringResource(R.string.move_to_recycle_bin_title)
                }
            )
        },
        text = {
            Column {
                Text(
                    text = if (isPermanent || bypassTrash) {
                        if (itemCount == 1) {
                            stringResource(R.string.delete_permanently_single)
                        } else {
                            stringResource(R.string.delete_permanently_multiple, itemCount)
                        }
                    } else {
                        if (itemCount == 1) {
                            stringResource(R.string.move_to_recycle_bin_single)
                        } else {
                            stringResource(R.string.move_to_recycle_bin_multiple, itemCount)
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
                            text = stringResource(R.string.delete_permanently_bypass),
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
                    text = if (isPermanent || bypassTrash) {
                        stringResource(R.string.delete)
                    } else {
                        stringResource(R.string.move_to_bin_action)
                    },
                    color = MaterialTheme.colorScheme.error
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}
