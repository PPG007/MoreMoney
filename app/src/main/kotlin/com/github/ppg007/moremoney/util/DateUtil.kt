package com.github.ppg007.moremoney.util

import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.YearMonth
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters
import java.time.DayOfWeek

/** 毫秒时间区间，闭区间。 */
data class DateRange(
  val startMs: Long = 0,
  val endMs: Long = 0,
)

/**
 * 日期工具：全部按本地时区计算，日键 `YYYY-MM-DD`、月键 `YYYY-MM`。
 *
 * UI 与统计使用同一套本地时区日键，避免跨时区或夏令时导致分组漂移。
 */
object DateUtil {
  private const val MILLIS_PER_DAY = 86_400_000L
  private val WEEK_NAMES = arrayOf("周日", "周一", "周二", "周三", "周四", "周五", "周六")
  private val DAY_KEY_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd")
  private val MONTH_KEY_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM")

  fun zone(): ZoneId = ZoneId.systemDefault()

  fun dayKey(date: LocalDate): String = date.format(DAY_KEY_FORMAT)

  fun dayKey(timestamp: Long): String = dayKey(toLocalDate(timestamp))

  fun monthKey(date: LocalDate): String = date.format(MONTH_KEY_FORMAT)

  fun monthKey(timestamp: Long): String = monthKey(toLocalDate(timestamp))

  fun today(): LocalDate = LocalDate.now(zone())

  fun toLocalDate(timestamp: Long): LocalDate =
    Instant.ofEpochMilli(timestamp).atZone(zone()).toLocalDate()

  fun toLocalDateTime(timestamp: Long): LocalDateTime =
    Instant.ofEpochMilli(timestamp).atZone(zone()).toLocalDateTime()

  /**
   * Material3 日期组件使用“UTC 零点毫秒”，与本地时区的 [toLocalDate] 不同。
   *
   * 只用于日期选择器这类按“日”的 UI 往返，不用于业务时间戳。
   */
  fun toUtcMillis(date: LocalDate): Long = date.toEpochDay() * MILLIS_PER_DAY

  fun fromUtcMillis(millis: Long): LocalDate =
    LocalDate.ofEpochDay(Math.floorDiv(millis, MILLIS_PER_DAY))

  fun parseDayKey(key: String): LocalDate =
    try {
      LocalDate.parse(key, DAY_KEY_FORMAT)
    } catch (error: Exception) {
      LocalDate.of(1970, 1, 1)
    }

  fun parseMonthKey(key: String): YearMonth =
    try {
      YearMonth.parse(key, MONTH_KEY_FORMAT)
    } catch (error: Exception) {
      YearMonth.of(1970, 1)
    }

  fun daysInMonth(year: Int, month1To12: Int): Int =
    try {
      YearMonth.of(year, month1To12).lengthOfMonth()
    } catch (error: Exception) {
      0
    }

  /** 周起始日：1=周一 … 7=周日；越界回退到周一。 */
  fun startOfWeek(date: LocalDate, weekStart: Int): LocalDate {
    val normalized = weekStart.coerceIn(1, 7)
    val target = if (normalized == 7) DayOfWeek.SUNDAY else DayOfWeek.of(normalized)
    return date.with(TemporalAdjusters.previousOrSame(target))
  }

  fun rangeOfMonth(monthKey: String): DateRange {
    val yearMonth = parseMonthKey(monthKey)
    val start = yearMonth.atDay(1).atStartOfDay(zone()).toInstant().toEpochMilli()
    val end = yearMonth.atEndOfMonth().atTime(LocalTime.of(23, 59, 59, 999_000_000))
      .atZone(zone()).toInstant().toEpochMilli()
    return DateRange(startMs = start, endMs = end)
  }

  fun rangeOfDay(dayKey: String): DateRange {
    val date = parseDayKey(dayKey)
    val start = date.atStartOfDay(zone()).toInstant().toEpochMilli()
    val end = date.atTime(LocalTime.of(23, 59, 59, 999_000_000)).atZone(zone()).toInstant().toEpochMilli()
    return DateRange(startMs = start, endMs = end)
  }

  fun addMonths(monthKey: String, delta: Int): String =
    parseMonthKey(monthKey).plusMonths(delta.toLong()).format(MONTH_KEY_FORMAT)

  fun formatMonthCn(monthKey: String): String {
    val yearMonth = parseMonthKey(monthKey)
    return "${yearMonth.monthValue}月"
  }

  fun formatMonthCnWithYear(monthKey: String): String {
    val yearMonth = parseMonthKey(monthKey)
    return "${yearMonth.year}年${yearMonth.monthValue}月"
  }

  fun formatDayCn(dayKey: String): String {
    val date = parseDayKey(dayKey)
    return "${date.monthValue}月${date.dayOfMonth}日 ${WEEK_NAMES[date.dayOfWeek.value % 7]}"
  }

  fun formatShortDay(dayKey: String): String {
    val date = parseDayKey(dayKey)
    return "${date.monthValue}月${date.dayOfMonth}日"
  }

  fun weekdayName(date: LocalDate): String = WEEK_NAMES[date.dayOfWeek.value % 7]

  /** 备份状态等场景使用的短日期时间：`2026-11-23 20:31`。 */
  fun formatShortDateTime(timestamp: Long): String {
    val dateTime = toLocalDateTime(timestamp)
    return "${dateTime.year}-${dateTime.monthValue.toString().padStart(2, '0')}-" +
      "${dateTime.dayOfMonth.toString().padStart(2, '0')} " +
      "${dateTime.hour.toString().padStart(2, '0')}:${dateTime.minute.toString().padStart(2, '0')}"
  }

  /** 生成时间段内每一天的日键（闭区间）。 */
  fun dayKeysBetween(startMs: Long, endMs: Long): List<String> {
    if (endMs < startMs) {
      return emptyList()
    }
    val start = toLocalDate(startMs)
    val end = toLocalDate(endMs)
    val result = ArrayList<String>()
    var cursor = start
    while (!cursor.isAfter(end) && result.size < 400) {
      result.add(dayKey(cursor))
      cursor = cursor.plusDays(1)
    }
    return result
  }

  fun occurredAt(dayKey: String, time: LocalTime = LocalTime.now()): Long =
    parseDayKey(dayKey).atTime(time).atZone(zone()).toInstant().toEpochMilli()

  fun nowDayKey(): String = dayKey(today())
}
