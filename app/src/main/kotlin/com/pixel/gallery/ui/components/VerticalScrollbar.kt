package com.pixel.gallery.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import kotlin.math.max

/**
 * A custom interactive scrollbar for LazyVerticalGrid.
 */
@Composable
fun VerticalScrollbar(
    gridState: LazyGridState,
    modifier: Modifier = Modifier
) {
    val coroutineScope = rememberCoroutineScope()
    
    val info = gridState.layoutInfo
    val totalItems = info.totalItemsCount
    val visibleItems = info.visibleItemsInfo.size
    
    if (totalItems <= visibleItems || totalItems == 0) return

    val firstVisibleItemIndex = gridState.firstVisibleItemIndex
    val firstVisibleItemScrollOffset = gridState.firstVisibleItemScrollOffset
    
    // Calculate scroll percentage
    // This is an approximation for Lazy grids
    val scrollPercentage = remember(firstVisibleItemIndex, firstVisibleItemScrollOffset, totalItems) {
        if (totalItems == 0) 0f
        else {
            val totalScrollableIcons = totalItems - visibleItems
            (firstVisibleItemIndex.toFloat() / max(1, totalScrollableIcons))
        }
    }

    var isDragging by remember { mutableStateOf(false) }
    val alpha by animateFloatAsState(
        targetValue = if (isDragging || gridState.isScrollInProgress) 1f else 0f,
        animationSpec = tween(durationMillis = 500),
        label = "scrollbar_alpha"
    )

    BoxWithConstraints(
        modifier = modifier
            .fillMaxHeight()
            .width(32.dp)
            .alpha(alpha)
    ) {
        val maxHeight = constraints.maxHeight.toFloat()
        val scrollbarHeight = 60.dp
        val scrollbarHeightPx = scrollbarHeight.value * 3 // Approximation for dp to px
        
        val trackHeight = maxHeight - scrollbarHeightPx
        val thumbOffset = scrollPercentage * trackHeight

        Box(
            modifier = Modifier
                .offset(y = (thumbOffset / 3).dp) // Back to dp
                .align(Alignment.TopEnd)
                .width(6.dp)
                .height(scrollbarHeight)
                .padding(end = 2.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.6f))
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDragStart = { isDragging = true },
                        onDragEnd = { isDragging = false },
                        onDragCancel = { isDragging = false },
                        onDrag = { change, dragAmount ->
                            change.consume()
                            val newScrollPercentage = (scrollPercentage + dragAmount.y / trackHeight).coerceIn(0f, 1f)
                            val targetIndex = (newScrollPercentage * (totalItems - 1)).toInt().coerceIn(0, totalItems - 1)
                            coroutineScope.launch {
                                gridState.scrollToItem(targetIndex)
                            }
                        }
                    )
                }
        )
    }
}
