package com.pixel.gallery.utils

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object FilenameDateParser {
    // Matches YYYYMMDD-HHMMSS or YYYYMMDD_HHMMSS
    // e.g. 20260531-144922, 20260531_144922
    private val pattern1 = Regex("""(?<!\d)(19|20\d{2})(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])[-_]([01]\d|2[0-3])([0-5]\d)([0-5]\d)(?!\d)""")

    // Matches YYYY-MM-DD-HH-MM-SS or YYYY_MM_DD_HH_MM_SS
    // e.g. 2026-05-31-14-49-22, 2026_05_31_14_49_22
    private val pattern2 = Regex("""(?<!\d)(19|20\d{2})[-_](0[1-9]|1[0-2])[-_](0[1-9]|[12]\d|3[01])[-_]([01]\d|2[0-3])[-_]([0-5]\d)[-_]([0-5]\d)(?!\d)""")

    // Matches YYYYMMDDHHMMSS (no separator)
    // e.g. 20260531144922
    private val pattern3 = Regex("""(?<!\d)(19|20\d{2})(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])([01]\d|2[0-3])([0-5]\d)([0-5]\d)(?!\d)""")

    // Matches 13-digit Unix millisecond timestamp
    // e.g. 1685976340633
    private val pattern4 = Regex("""(?<!\d)([12]\d{12})(?!\d)""")

    fun parseDateFromFilename(filename: String): Long? {
        // Try pattern 1
        pattern1.find(filename)?.let { matchResult ->
            val groups = matchResult.groupValues
            val year = groups[1]
            val month = groups[2]
            val day = groups[3]
            val hour = groups[4]
            val minute = groups[5]
            val second = groups[6]
            return parseDateTimeString("$year$month$day-$hour$minute$second", "yyyyMMdd-HHmmss")
        }

        // Try pattern 2
        pattern2.find(filename)?.let { matchResult ->
            val groups = matchResult.groupValues
            val year = groups[1]
            val month = groups[2]
            val day = groups[3]
            val hour = groups[4]
            val minute = groups[5]
            val second = groups[6]
            return parseDateTimeString("$year-$month-$day-$hour-$minute-$second", "yyyy-MM-dd-HH-MM-ss")
        }

        // Try pattern 3
        pattern3.find(filename)?.let { matchResult ->
            val groups = matchResult.groupValues
            val year = groups[1]
            val month = groups[2]
            val day = groups[3]
            val hour = groups[4]
            val minute = groups[5]
            val second = groups[6]
            return parseDateTimeString("$year$month$day$hour$minute$second", "yyyyMMddHHmmss")
        }

        // Try pattern 4
        pattern4.find(filename)?.let { matchResult ->
            val timestampStr = matchResult.groupValues[1]
            return timestampStr.toLongOrNull()
        }

        return null
    }

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
