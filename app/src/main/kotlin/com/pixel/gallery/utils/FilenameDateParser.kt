package com.pixel.gallery.utils

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object FilenameDateParser {


    fun parseExifDateTime(exifDateTime: String): Long? {
        return try {
            val sdf = SimpleDateFormat("yyyy:MM:dd HH:mm:ss", Locale.US)
            sdf.parse(exifDateTime)?.time
        } catch (e: Exception) {
            null
        }
    }

    fun formatEpochMillis(millis: Long): String {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = millis
        
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        val suffix = getDaySuffix(day)
        
        // Month: e.g. "Jun"
        val monthSdf = SimpleDateFormat("MMM", Locale.US)
        val month = monthSdf.format(calendar.time)
        
        // Year: e.g. "2026"
        val year = calendar.get(Calendar.YEAR)
        
        // Day of week: e.g. "Sat"
        val dayOfWeekSdf = SimpleDateFormat("E", Locale.US)
        val dayOfWeek = dayOfWeekSdf.format(calendar.time)
        
        // Time: e.g. "7:02 pm"
        val timeSdf = SimpleDateFormat("h:mm a", Locale.US)
        val time = timeSdf.format(calendar.time).lowercase(Locale.US)
        
        return "${day}${suffix} ${month} ${year}, ${dayOfWeek}, ${time}"
    }

    private fun getDaySuffix(day: Int): String {
        if (day in 11..13) return "th"
        return when (day % 10) {
            1 -> "st"
            2 -> "nd"
            3 -> "rd"
            else -> "th"
        }
    }

    private fun parseDateTimeString(dateStr: String, pattern: String): Long? {
        return try {
            val sdf = SimpleDateFormat(pattern, Locale.US)
            sdf.timeZone = TimeZone.getDefault()
            sdf.parse(dateStr)?.time
        } catch (e: Exception) {
            null
        }
    }
}
