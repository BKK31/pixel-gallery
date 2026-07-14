package com.pixel.gallery.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.draggable
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.rememberDraggableState
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlin.math.max

/**
 * A custom interactive scrollbar for LazyVerticalGrid.
 */
internal fun calculateScrollbarProgress(
    firstVisibleItemIndex: Int,
    totalItems: Int,
    visibleItems: Int
): Float {
    val totalScrollable = totalItems - visibleItems
    if (totalItems <= 0 || totalScrollable <= 0) return 0f
    return (firstVisibleItemIndex.toFloat() / totalScrollable).coerceIn(0f, 1f)
}

internal fun calculateTargetIndexFromThumbOffset(
    thumbTopPx: Float,
    trackHeightPx: Float,
    totalItems: Int,
    visibleItems: Int
): Int {
    if (totalItems <= 0) return 0

    val totalScrollable = totalItems - visibleItems
    if (totalScrollable <= 0 || trackHeightPx <= 0f) return 0

    val fraction = (thumbTopPx / trackHeightPx).coerceIn(0f, 1f)
    return (fraction * totalScrollable)
        .toInt()
        .coerceIn(0, totalItems - 1)
}

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

    val scrollbarHeight = 60.dp
    val thumbVisualWidth = 4.dp
    val thumbDraggedVisualWidth = 8.dp
    val thumbTouchWidth = 20.dp
    val thumbDraggedTouchWidth = 28.dp

    val scrollPercentage = remember(
        firstVisibleItemIndex,
        totalItems,
        visibleItems
    ) {
        calculateScrollbarProgress(firstVisibleItemIndex, totalItems, visibleItems)
    }

    var isDragging by remember { mutableStateOf(false) }
    var dragThumbOffsetPx by remember { mutableFloatStateOf(0f) }
    var scrollJob by remember { mutableStateOf<Job?>(null) }

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
        targetValue = if (isDragging) thumbDraggedVisualWidth else thumbVisualWidth,
        animationSpec = tween(durationMillis = 200),
        label = "scrollbar_width"
    )
    val thumbHitWidth by animateDpAsState(
        targetValue = if (isDragging) thumbDraggedTouchWidth else thumbTouchWidth,
        animationSpec = tween(durationMillis = 200),
        label = "scrollbar_hit_width"
    )

    BoxWithConstraints(
        modifier = modifier
            .fillMaxHeight()
            .width(56.dp)
            .alpha(alpha)
    ) {
        val density = LocalDensity.current
        val scrollbarHeightPx = with(density) { scrollbarHeight.toPx() }
        val maxHeight = constraints.maxHeight.toFloat()
        val trackHeight = max(1f, maxHeight - scrollbarHeightPx)
        val thumbOffsetPx = if (isDragging) dragThumbOffsetPx else scrollPercentage * trackHeight
        val thumbOffsetDp = with(density) { thumbOffsetPx.toDp() }
        val currentTrackHeight = rememberUpdatedState(trackHeight)
        val currentTotalItems = rememberUpdatedState(totalItems)
        val currentVisibleItems = rememberUpdatedState(visibleItems)
        val currentThumbOffsetPx = rememberUpdatedState(thumbOffsetPx)

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

        val draggableState = rememberDraggableState { delta ->
            val nextThumbOffsetPx = (dragThumbOffsetPx + delta).coerceIn(0f, currentTrackHeight.value)
            dragThumbOffsetPx = nextThumbOffsetPx

            val targetIndex = calculateTargetIndexFromThumbOffset(
                thumbTopPx = nextThumbOffsetPx,
                trackHeightPx = currentTrackHeight.value,
                totalItems = currentTotalItems.value,
                visibleItems = currentVisibleItems.value
            )

            scrollJob?.cancel()
            scrollJob = coroutineScope.launch {
                gridState.scrollToItem(targetIndex)
            }
        }

        // Thumb and draggable hit target.
        Box(
            modifier = Modifier
                .offset(y = thumbOffsetDp)
                .align(Alignment.TopEnd)
                .padding(end = 4.dp)
                .width(thumbHitWidth)
                .height(scrollbarHeight)
                .draggable(
                    state = draggableState,
                    orientation = Orientation.Vertical,
                    onDragStarted = {
                        isDragging = true
                        dragThumbOffsetPx = currentThumbOffsetPx.value
                    },
                    onDragStopped = {
                        isDragging = false
                        scrollJob?.cancel()
                        scrollJob = null
                    }
                )
        ) {
            Box(
                modifier = Modifier
                    .align(Alignment.CenterEnd)
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
}
