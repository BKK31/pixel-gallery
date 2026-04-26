package com.pixel.gallery.ui.utils

import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.*
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.unit.IntRect
import androidx.compose.ui.unit.round
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * A highly robust and fluid modifier that enables "glide to select" functionality.
 * Inspired by the Google Photos selection experience.
 */
@Composable
fun Modifier.photoGridDragSelect(
    gridState: LazyGridState,
    items: List<Any>,
    selectedIds: Set<Long>,
    onSelectionChange: (Set<Long>) -> Unit,
    isPhoto: (Int) -> Boolean,
    getPhotoId: (Int) -> Long
): Modifier {
    val scope = rememberCoroutineScope()
    val haptics = LocalHapticFeedback.current
    val viewConfiguration = LocalViewConfiguration.current
    
    // Use updated states to avoid restarting pointerInput when selection changes
    val currentSelectedIds by rememberUpdatedState(selectedIds)
    val currentItems by rememberUpdatedState(items)
    val currentSelectionChange by rememberUpdatedState(onSelectionChange)
    val currentIsPhoto by rememberUpdatedState(isPhoto)
    val currentGetPhotoId by rememberUpdatedState(getPhotoId)

    // State to track the active drag session - persistent across recompositions
    var dragInitialIndex by remember { mutableIntStateOf(-1) }
    var dragCurrentIndex by remember { mutableIntStateOf(-1) }
    var dragStartedWithSelection by remember { mutableStateOf(false) }
    var initialSelectedIdsState by remember { mutableStateOf(setOf<Long>()) }
    
    // Auto-scroll state
    var autoScrollSpeed by remember { mutableFloatStateOf(0f) }
    var lastPointerPosition by remember { mutableStateOf(Offset.Unspecified) }

    // Continuous auto-scroll and selection update loop
    LaunchedEffect(autoScrollSpeed) {
        if (autoScrollSpeed != 0f) {
            while (isActive) {
                gridState.scrollBy(autoScrollSpeed)
                
                // Update selection while scrolling, even if finger is stationary
                if (lastPointerPosition != Offset.Unspecified && dragInitialIndex != -1) {
                    val index = gridState.getItemIndexAt(lastPointerPosition)
                    if (index != null && index != dragCurrentIndex) {
                        dragCurrentIndex = index
                        performUpdateSelection(
                            initialSelectedIds = initialSelectedIdsState,
                            dragInitialIndex = dragInitialIndex,
                            dragCurrentIndex = dragCurrentIndex,
                            dragStartedWithSelection = dragStartedWithSelection,
                            items = currentItems,
                            isPhoto = currentIsPhoto,
                            getPhotoId = currentGetPhotoId,
                            onSelectionChange = currentSelectionChange
                        )
                    }
                }
                delay(10)
            }
        }
    }

    // pointerInput(Unit) ensures this coroutine is NOT restarted when selectedIds change,
    // which is the key to fluid continuous dragging.
    return this.pointerInput(Unit) {
        while (true) {
            awaitPointerEventScope {
                val down = awaitFirstDown(pass = PointerEventPass.Initial)
                var dragStarted = false
                
                val longPressTimeout = viewConfiguration.longPressTimeoutMillis
                val touchSlop = viewConfiguration.touchSlop
                
                val longPressJob = scope.launch {
                    delay(longPressTimeout)
                    val index = gridState.getItemIndexAt(down.position)
                    if (index != null && currentIsPhoto(index)) {
                        val id = currentGetPhotoId(index)
                        
                        dragStarted = true
                        dragInitialIndex = index
                        dragCurrentIndex = index
                        initialSelectedIdsState = currentSelectedIds
                        dragStartedWithSelection = !currentSelectedIds.contains(id)
                        
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                        
                        performUpdateSelection(
                            initialSelectedIds = initialSelectedIdsState,
                            dragInitialIndex = dragInitialIndex,
                            dragCurrentIndex = dragCurrentIndex,
                            dragStartedWithSelection = dragStartedWithSelection,
                            items = currentItems,
                            isPhoto = currentIsPhoto,
                            getPhotoId = currentGetPhotoId,
                            onSelectionChange = currentSelectionChange
                        )
                    }
                }

                try {
                    do {
                        val event = awaitPointerEvent(pass = PointerEventPass.Initial)
                        val change = event.changes.first()
                        lastPointerPosition = change.position
                        
                        if (dragStarted) {
                            change.consume()
                            
                            val index = gridState.getItemIndexAt(change.position)
                            
                            // Auto-scroll logic
                            val viewHeight = size.height
                            val threshold = 100f
                            autoScrollSpeed = when {
                                change.position.y < threshold -> - (threshold - change.position.y) / 2f
                                change.position.y > viewHeight - threshold -> (change.position.y - (viewHeight - threshold)) / 2f
                                else -> 0f
                            }

                            if (index != null && index != dragCurrentIndex) {
                                dragCurrentIndex = index
                                performUpdateSelection(
                                    initialSelectedIds = initialSelectedIdsState,
                                    dragInitialIndex = dragInitialIndex,
                                    dragCurrentIndex = dragCurrentIndex,
                                    dragStartedWithSelection = dragStartedWithSelection,
                                    items = currentItems,
                                    isPhoto = currentIsPhoto,
                                    getPhotoId = currentGetPhotoId,
                                    onSelectionChange = currentSelectionChange
                                )
                            }
                        } else {
                            val diff = change.position - down.position
                            if (kotlin.math.hypot(diff.x, diff.y) > touchSlop) {
                                longPressJob.cancel()
                            }
                        }
                    } while (change.pressed)
                } finally {
                    longPressJob.cancel()
                    dragInitialIndex = -1
                    dragCurrentIndex = -1
                    autoScrollSpeed = 0f
                    lastPointerPosition = Offset.Unspecified
                    dragStarted = false
                }
            }
        }
    }
}

private fun performUpdateSelection(
    initialSelectedIds: Set<Long>,
    dragInitialIndex: Int,
    dragCurrentIndex: Int,
    dragStartedWithSelection: Boolean,
    items: List<Any>,
    isPhoto: (Int) -> Boolean,
    getPhotoId: (Int) -> Long,
    onSelectionChange: (Set<Long>) -> Unit
) {
    if (dragInitialIndex == -1 || dragCurrentIndex == -1) return
    
    val start = minOf(dragInitialIndex, dragCurrentIndex)
    val end = maxOf(dragInitialIndex, dragCurrentIndex)
    
    val rangeIds = (start..end).filter { isPhoto(it) }.map { getPhotoId(it) }.toSet()
    
    val newSelection = if (dragStartedWithSelection) {
        initialSelectedIds + rangeIds
    } else {
        initialSelectedIds - rangeIds
    }
    onSelectionChange(newSelection)
}

private fun LazyGridState.getItemIndexAt(offset: Offset): Int? {
    return layoutInfo.visibleItemsInfo.find { item ->
        val itemRect = IntRect(item.offset, item.size)
        itemRect.contains(offset.round())
    }?.index
}
