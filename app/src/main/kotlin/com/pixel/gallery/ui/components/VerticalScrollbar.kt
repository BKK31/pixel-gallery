package com.pixel.gallery.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlin.math.max

/**
 * A custom interactive scrollbar for LazyVerticalGrid.
 */
@Composable
fun VerticalScrollbar(
    gridState: LazyGridState,
    modifier: Modifier = Modifier,
    getLabel: ((Int) -> String?)? = null
) {
    val coroutineScope = rememberCoroutineScope()
    
    val info = gridState.layoutInfo
    val totalItems = info.totalItemsCount
    val visibleItems = info.visibleItemsInfo.size
    
    if (totalItems <= visibleItems || totalItems == 0) return

    val firstVisibleItemIndex = gridState.firstVisibleItemIndex
    val firstVisibleItemScrollOffset = gridState.firstVisibleItemScrollOffset
    
    val scrollbarHeight = 60.dp

    // Keep thumb position close to actual viewport position.
    val scrollPercentage = remember(
        firstVisibleItemIndex,
        firstVisibleItemScrollOffset,
        totalItems,
        visibleItems
    ) {
        val totalScrollable = max(1, totalItems - visibleItems)
        (firstVisibleItemIndex.toFloat() / totalScrollable).coerceIn(0f, 1f)
    }

    var isDragging by remember { mutableStateOf(false) }
    
    // Faint but visible when idle, bright during scroll/drag
    val alpha by animateFloatAsState(
        targetValue = when {
            isDragging -> 1f
            gridState.isScrollInProgress -> 0.8f
            else -> 0.3f
        },
        animationSpec = tween(durationMillis = 300),
        label = "scrollbar_alpha"
    )

    val thumbWidth by animateDpAsState(
        targetValue = if (isDragging) 8.dp else 4.dp,
        animationSpec = tween(durationMillis = 200),
        label = "scrollbar_width"
    )

    BoxWithConstraints(
        modifier = modifier
            .fillMaxHeight()
            .width(56.dp)
            .alpha(alpha)
            .pointerInput(gridState) {
                var scrollJob: Job? = null
                val scrollbarHeightPx = scrollbarHeight.toPx()
                val trackHeight = max(1f, size.height.toFloat() - scrollbarHeightPx)

                fun jumpTo(y: Float) {
                    val centeredY = (y - scrollbarHeightPx / 2f).coerceIn(0f, trackHeight)
                    val fraction = centeredY / trackHeight
                    val info = gridState.layoutInfo
                    val total = info.totalItemsCount
                    val visible = info.visibleItemsInfo.size
                    val totalScrollable = max(1, total - visible)
                    val targetIndex = (fraction * totalScrollable).toInt().coerceIn(0, total - 1)

                    scrollJob?.cancel()
                    scrollJob = coroutineScope.launch {
                        gridState.scrollToItem(targetIndex)
                    }
                }

                detectDragGestures(
                    onDragStart = { offset ->
                        isDragging = true
                        jumpTo(offset.y)
                    },
                    onDragEnd = { 
                        isDragging = false 
                        scrollJob?.cancel()
                    },
                    onDragCancel = { 
                        isDragging = false 
                        scrollJob?.cancel()
                    },
                    onDrag = { change, _ ->
                        change.consume()
                        jumpTo(change.position.y)
                    }
                )
            }
    ) {
        val density = LocalDensity.current
        val scrollbarHeightPx = with(density) { scrollbarHeight.toPx() }
        val maxHeight = constraints.maxHeight.toFloat()
        val trackHeight = max(1f, maxHeight - scrollbarHeightPx)
        val thumbOffsetPx = scrollPercentage * trackHeight
        val thumbOffsetDp = with(density) { thumbOffsetPx.toDp() }

        // Faint vertical track line
        Box(
            modifier = Modifier
                .align(Alignment.CenterEnd)
                .padding(end = 6.dp)
                .fillMaxHeight()
                .width(1.dp)
                .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.05f))
        )

        // Date/Alphabet tooltip bubble
        if (isDragging && getLabel != null) {
            val label = getLabel(firstVisibleItemIndex)
            if (!label.isNullOrEmpty()) {
                Surface(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(
                            x = (-24).dp,
                            y = thumbOffsetDp + 8.dp // Center vertically relative to thumb
                        ),
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.primaryContainer,
                    tonalElevation = 4.dp
                ) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                    )
                }
            }
        }

        // Thumb
        Box(
            modifier = Modifier
                .offset(y = thumbOffsetDp)
                .align(Alignment.TopEnd)
                .padding(end = 4.dp)
                .width(thumbWidth)
                .height(scrollbarHeight)
                .clip(CircleShape)
                .background(
                    if (isDragging) MaterialTheme.colorScheme.primary 
                    else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                )
        )
    }
}
