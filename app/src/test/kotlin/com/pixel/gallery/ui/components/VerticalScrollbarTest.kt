package com.pixel.gallery.ui.components

import org.junit.Assert.assertEquals
import org.junit.Test

class VerticalScrollbarTest {

    @Test
    fun `progress clamps at the ends`() {
        assertEquals(0f, calculateScrollbarProgress(0, 100, 10), 0f)
        assertEquals(1f, calculateScrollbarProgress(90, 100, 10), 0f)
        assertEquals(0f, calculateScrollbarProgress(5, 5, 5), 0f)
    }

    @Test
    fun `thumb offset maps to target index across the track`() {
        assertEquals(0, calculateTargetIndexFromThumbOffset(0f, 100f, 100, 10))
        assertEquals(45, calculateTargetIndexFromThumbOffset(50f, 100f, 100, 10))
        assertEquals(90, calculateTargetIndexFromThumbOffset(100f, 100f, 100, 10))
    }

    @Test
    fun `target index clamps when the thumb leaves the track`() {
        assertEquals(0, calculateTargetIndexFromThumbOffset(-20f, 100f, 100, 10))
        assertEquals(90, calculateTargetIndexFromThumbOffset(140f, 100f, 100, 10))
    }
}
