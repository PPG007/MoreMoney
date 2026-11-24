package com.github.ppg007.moremoney.util

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

class DateUtilTest {
  @Test
  fun formatsDayAndMonthKeys() {
    val date = LocalDate.of(2026, 11, 9)
    assertEquals("2026-11-09", DateUtil.dayKey(date))
    assertEquals("2026-11", DateUtil.monthKey(date))
    assertEquals("11月", DateUtil.formatMonthCn("2026-11"))
    assertEquals("11月9日 周一", DateUtil.formatDayCn("2026-11-09"))
  }

  @Test
  fun computesDaysInMonthIncludingLeapYears() {
    assertEquals(28, DateUtil.daysInMonth(2026, 2))
    assertEquals(29, DateUtil.daysInMonth(2024, 2))
    assertEquals(30, DateUtil.daysInMonth(2026, 11))
    assertEquals(31, DateUtil.daysInMonth(2026, 12))
  }

  @Test
  fun computesWeekStartForMondayAndSunday() {
    val date = LocalDate.of(2026, 11, 9)
    assertEquals("2026-11-09", DateUtil.dayKey(DateUtil.startOfWeek(date, 1)))
    assertEquals("2026-11-08", DateUtil.dayKey(DateUtil.startOfWeek(date, 7)))
    val sunday = LocalDate.of(2026, 11, 8)
    assertEquals("2026-11-02", DateUtil.dayKey(DateUtil.startOfWeek(sunday, 1)))
  }

  @Test
  fun resolvesMonthRangeBoundaries() {
    val range = DateUtil.rangeOfMonth("2026-02")
    assertEquals("2026-02-01", DateUtil.dayKey(range.startMs))
    assertEquals("2026-02-28", DateUtil.dayKey(range.endMs))
    assertEquals(0, DateUtil.toLocalDateTime(range.startMs).hour)
    assertEquals(23, DateUtil.toLocalDateTime(range.endMs).hour)
  }

  @Test
  fun addsMonthsAcrossYearBoundary() {
    assertEquals("2025-12", DateUtil.addMonths("2026-01", -1))
    assertEquals("2027-01", DateUtil.addMonths("2026-12", 1))
    assertEquals("2027-01", DateUtil.addMonths("2026-11", 2))
  }

  @Test
  fun convertsDatesToMaterialUtcMillis() {
    val date = LocalDate.of(2026, 11, 9)
    assertEquals(1_794_182_400_000L, DateUtil.toUtcMillis(date))
    assertEquals(date, DateUtil.fromUtcMillis(DateUtil.toUtcMillis(date)))
    // Material3 的毫秒按 UTC 零点传入；即使带时分也按 UTC 日期还原，不受设备时区影响。
    assertEquals(date, DateUtil.fromUtcMillis(DateUtil.toUtcMillis(date) + 12 * 3_600_000L))
    // 1900 年在 UTC 上是负数毫秒，floorDiv 不能退化成截断除法。
    assertEquals(LocalDate.of(1900, 1, 1), DateUtil.fromUtcMillis(DateUtil.toUtcMillis(LocalDate.of(1900, 1, 1))))
  }

  @Test
  fun parsesDayKeysToLocalDates() {
    val date = DateUtil.parseDayKey("2026-11-09")
    assertEquals(2026, date.year)
    assertEquals(11, date.monthValue)
    assertEquals(9, date.dayOfMonth)
    assertEquals("1970-01-01", DateUtil.dayKey(DateUtil.parseDayKey("bad")))
  }
}
