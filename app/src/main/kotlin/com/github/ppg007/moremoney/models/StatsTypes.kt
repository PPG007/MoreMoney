package com.github.ppg007.moremoney.models

/** 统计周期类型。 */
enum class PeriodType {
  TODAY,
  WEEK,
  MONTH,
  YEAR,
  ALL,
  CUSTOM,
}

/** 趋势图的桶粒度。 */
enum class BucketGranularity {
  DAY,
  WEEK,
  MONTH,
}

/** 统计过滤条件；bookIds 为空表示不限。 */
data class StatsFilter(
  val bookIds: List<String> = emptyList(),
  val startMs: Long = 0,
  val endMs: Long = 0,
  val excludeBookIds: List<String> = emptyList(),
  val weekStart: Int = 1,
)

data class PeriodRange(
  val startMs: Long = 0,
  val endMs: Long = 0,
  val label: String = "",
)

data class CategorySum(
  val categoryId: String = "",
  val name: String = "",
  val icon: String = "",
  val color: String = "",
  val cents: Long = 0,
)

data class BookSum(
  val bookId: String = "",
  val name: String = "",
  val icon: String = "",
  val color: String = "",
  val cents: Long = 0,
)

data class DaySum(
  val dayKey: String = "",
  val cents: Long = 0,
)

data class BucketSum(
  val key: String = "",
  val label: String = "",
  val cents: Long = 0,
)

data class DailyStats(
  val totalCents: Long = 0,
  val avgCents: Long = 0,
  val maxCents: Long = 0,
  val maxDayKey: String = "",
  val days: Int = 0,
)
