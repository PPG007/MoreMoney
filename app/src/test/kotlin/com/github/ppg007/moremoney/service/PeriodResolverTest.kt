package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.models.BucketGranularity
import com.github.ppg007.moremoney.models.PeriodType
import com.github.ppg007.moremoney.util.DateUtil
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneId

class PeriodResolverTest {
  private val zone = ZoneId.systemDefault()
  private val now =
    LocalDateTime.of(2026, 11, 9, 15, 30).atZone(zone).toInstant()

  @Test
  fun resolvesTodayBoundaries() {
    val range = PeriodResolver.resolve(PeriodType.TODAY, now, 1, zone)
    assertEquals("2026-11-09", DateUtil.dayKey(range.startMs))
    assertEquals("2026-11-09", DateUtil.dayKey(range.endMs))
    assertEquals(0, DateUtil.toLocalDateTime(range.startMs).hour)
    assertEquals(23, DateUtil.toLocalDateTime(range.endMs).hour)
    assertEquals("今天", range.label)
  }

  @Test
  fun resolvesWeekStartingMonday() {
    val range = PeriodResolver.resolve(PeriodType.WEEK, now, 1, zone)
    assertEquals("2026-11-09", DateUtil.dayKey(range.startMs))
    assertEquals("2026-11-15", DateUtil.dayKey(range.endMs))
  }

  @Test
  fun resolvesWeekStartingSunday() {
    val range = PeriodResolver.resolve(PeriodType.WEEK, now, 7, zone)
    assertEquals("2026-11-08", DateUtil.dayKey(range.startMs))
    assertEquals("2026-11-14", DateUtil.dayKey(range.endMs))
  }

  @Test
  fun resolvesMonthBoundariesIncludingLeapFebruary() {
    val normal = PeriodResolver.resolve(PeriodType.MONTH, now, 1, zone)
    assertEquals("2026-11-01", DateUtil.dayKey(normal.startMs))
    assertEquals("2026-11-30", DateUtil.dayKey(normal.endMs))
    val feb =
      PeriodResolver.resolve(
        PeriodType.MONTH,
        LocalDateTime.of(2026, 2, 15, 10, 0).atZone(zone).toInstant(),
        1,
        zone,
      )
    assertEquals("2026-02-28", DateUtil.dayKey(feb.endMs))
    val leap =
      PeriodResolver.resolve(
        PeriodType.MONTH,
        LocalDateTime.of(2024, 2, 15, 10, 0).atZone(zone).toInstant(),
        1,
        zone,
      )
    assertEquals("2024-02-29", DateUtil.dayKey(leap.endMs))
  }

  @Test
  fun resolvesYearAndAll() {
    val year = PeriodResolver.resolve(PeriodType.YEAR, now, 1, zone)
    assertEquals("2026-01-01", DateUtil.dayKey(year.startMs))
    assertEquals("2026-12-31", DateUtil.dayKey(year.endMs))
    val all = PeriodResolver.resolve(PeriodType.ALL, now, 1, zone)
    assertEquals(0L, all.startMs)
    assertEquals(now.toEpochMilli(), all.endMs)
  }

  @Test
  fun resolvesCrossYearCustomRange() {
    val range = PeriodResolver.custom("2025-12-20", "2026-01-10")
    val start = DateUtil.toLocalDate(range.startMs)
    val end = DateUtil.toLocalDate(range.endMs)
    assertEquals("2025-12-20", DateUtil.dayKey(start))
    assertEquals("2026-01-10", DateUtil.dayKey(end))
    val days = java.time.temporal.ChronoUnit.DAYS.between(start, end) + 1
    assertEquals(22L, days)
  }

  @Test
  fun rejectsReversedCustomRange() {
    var failed = false
    try {
      PeriodResolver.custom("2026-01-10", "2025-12-20")
    } catch (error: IllegalArgumentException) {
      failed = true
    }
    assertTrue(failed)
  }

  @Test
  fun mapsBucketGranularityByRangeLength() {
    val month = PeriodResolver.resolve(PeriodType.MONTH, now, 1, zone)
    assertEquals(BucketGranularity.DAY, PeriodResolver.bucketGranularity(month))
    val quarter = PeriodResolver.custom("2026-09-01", "2026-11-30")
    assertEquals(BucketGranularity.WEEK, PeriodResolver.bucketGranularity(quarter))
    val longRange = PeriodResolver.custom("2026-01-01", "2026-11-30")
    assertEquals(BucketGranularity.MONTH, PeriodResolver.bucketGranularity(longRange))
  }
}
