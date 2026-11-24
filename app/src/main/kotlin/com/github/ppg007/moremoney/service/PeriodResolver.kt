package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.models.BucketGranularity
import com.github.ppg007.moremoney.models.PeriodRange
import com.github.ppg007.moremoney.models.PeriodType
import com.github.ppg007.moremoney.util.DateUtil
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * 统计周期解析。所有边界都按本地时区计算，`endMs` 为当天 23:59:59.999。
 */
object PeriodResolver {
  private const val DAY_MS = 24L * 60 * 60 * 1000

  fun resolve(
    type: PeriodType,
    now: Instant,
    weekStart: Int,
    zone: ZoneId = ZoneId.systemDefault(),
  ): PeriodRange {
    val dateTime = ZonedDateTime.ofInstant(now, zone)
    val today = dateTime.toLocalDate()
    return when (type) {
      PeriodType.TODAY -> dayRange(today, zone, "今天")
      PeriodType.WEEK -> {
        val start = DateUtil.startOfWeek(today, weekStart)
        val end = start.plusDays(6)
        PeriodRange(
          startMs = start.atStartOfDay(zone).toInstant().toEpochMilli(),
          endMs = end.atTime(LocalTime.of(23, 59, 59, 999_000_000)).atZone(zone).toInstant().toEpochMilli(),
          label = "本周",
        )
      }
      PeriodType.MONTH -> {
        val start = today.withDayOfMonth(1)
        val end = today.withDayOfMonth(today.lengthOfMonth())
        PeriodRange(
          startMs = start.atStartOfDay(zone).toInstant().toEpochMilli(),
          endMs = end.atTime(LocalTime.of(23, 59, 59, 999_000_000)).atZone(zone).toInstant().toEpochMilli(),
          label = "${today.monthValue}月",
        )
      }
      PeriodType.YEAR -> {
        val start = today.withDayOfYear(1)
        val end = today.withDayOfYear(today.lengthOfYear())
        PeriodRange(
          startMs = start.atStartOfDay(zone).toInstant().toEpochMilli(),
          endMs = end.atTime(LocalTime.of(23, 59, 59, 999_000_000)).atZone(zone).toInstant().toEpochMilli(),
          label = "${today.year}年",
        )
      }
      PeriodType.ALL -> PeriodRange(startMs = 0, endMs = now.toEpochMilli(), label = "全部")
      PeriodType.CUSTOM -> dayRange(today, zone, "自定义")
    }
  }

  fun resolve(type: PeriodType, now: LocalDate, weekStart: Int): PeriodRange {
    val start = now.atStartOfDay(DateUtil.zone()).toInstant()
    return resolve(type, start, weekStart)
  }

  fun custom(startDayKey: String, endDayKey: String, zone: ZoneId = ZoneId.systemDefault()): PeriodRange {
    val start = DateUtil.parseDayKey(startDayKey)
    val end = DateUtil.parseDayKey(endDayKey)
    require(!start.isAfter(end)) { "开始日期不能晚于结束日期" }
    return PeriodRange(
      startMs = start.atStartOfDay(zone).toInstant().toEpochMilli(),
      endMs = end.atTime(LocalTime.of(23, 59, 59, 999_000_000)).atZone(zone).toInstant().toEpochMilli(),
      label = "${shortDay(startDayKey)}–${shortDay(endDayKey)}",
    )
  }

  fun bucketGranularity(range: PeriodRange): BucketGranularity {
    val days = ((range.endMs - range.startMs) / DAY_MS).toInt() + 1
    return when {
      days <= 31 -> BucketGranularity.DAY
      days <= 120 -> BucketGranularity.WEEK
      else -> BucketGranularity.MONTH
    }
  }

  fun shortDay(dayKey: String): String {
    val date = DateUtil.parseDayKey(dayKey)
    return "${date.monthValue}月${date.dayOfMonth}日"
  }

  /** 月份剩余天数（含今天）；跨月/未来月份返回整月天数。 */
  fun daysLeftInMonth(monthKey: String, today: LocalDate = DateUtil.today()): Int {
    val yearMonth = DateUtil.parseMonthKey(monthKey)
    val totalDays = yearMonth.lengthOfMonth()
    return if (today.year == yearMonth.year && today.monthValue == yearMonth.monthValue) {
      (totalDays - today.dayOfMonth + 1).coerceAtLeast(1)
    } else {
      totalDays
    }
  }

  private fun dayRange(date: LocalDate, zone: ZoneId, label: String): PeriodRange =
    PeriodRange(
      startMs = date.atStartOfDay(zone).toInstant().toEpochMilli(),
      endMs = date.atTime(LocalTime.of(23, 59, 59, 999_000_000)).atZone(zone).toInstant().toEpochMilli(),
      label = label,
    )

  /** 用于日历热力的月份 7 列网格起点：返回当月第一天所在周的周一。 */
  fun calendarGridStart(yearMonth: java.time.YearMonth): LocalDate =
    yearMonth.atDay(1).with(java.time.temporal.TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
}
