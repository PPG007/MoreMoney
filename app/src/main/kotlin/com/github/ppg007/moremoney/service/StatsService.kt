package com.github.ppg007.moremoney.service

import androidx.sqlite.db.SimpleSQLiteQuery
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.models.BucketGranularity
import com.github.ppg007.moremoney.models.BucketSum
import com.github.ppg007.moremoney.models.BookSum
import com.github.ppg007.moremoney.models.CategorySum
import com.github.ppg007.moremoney.models.DailyStats
import com.github.ppg007.moremoney.models.DaySum
import com.github.ppg007.moremoney.models.StatsFilter
import com.github.ppg007.moremoney.util.DateUtil

/**
 * 统计聚合服务：分类占比、趋势、日历热力共用。
 *
 * 金额全部为整数分；区间使用本地时区 `day_key`；`byDay` 对缺失日期补 0。
 * 归档账本统一排除；私密账本已取消，因此没有锁定/排除逻辑。
 */
class StatsService(private val db: MoreMoneyDatabase) {
  suspend fun sum(filter: StatsFilter): Long {
    val args = ArrayList<Any?>()
    val where = buildWhere(filter, args, "t.")
    val sql = "SELECT COALESCE(SUM(t.amount_cents), 0) AS total FROM txn t WHERE $where"
    return db.statsDao().sum(SimpleSQLiteQuery(sql, args.toTypedArray()))
  }

  suspend fun byCategory(filter: StatsFilter): List<CategorySum> {
    val args = ArrayList<Any?>()
    val where = buildWhere(filter, args, "t.")
    val sql =
      "SELECT c.id AS category_id, c.name AS category_name, c.icon AS category_icon, " +
        "c.color AS category_color, SUM(t.amount_cents) AS total " +
        "FROM txn t INNER JOIN category c ON c.id = t.category_id WHERE $where " +
        "GROUP BY c.id, c.name, c.icon, c.color ORDER BY total DESC, c.name ASC"
    return db.statsDao().categorySums(SimpleSQLiteQuery(sql, args.toTypedArray())).map {
      CategorySum(it.categoryId, it.name, it.icon, it.color, it.cents)
    }
  }

  suspend fun byBook(filter: StatsFilter): List<BookSum> {
    val args = ArrayList<Any?>()
    val where = buildWhere(filter, args, "t.")
    val sql =
      "SELECT b.id AS book_id, b.name AS book_name, b.icon AS book_icon, b.color AS book_color, " +
        "SUM(t.amount_cents) AS total " +
        "FROM txn t INNER JOIN book b ON b.id = t.book_id WHERE $where " +
        "GROUP BY b.id, b.name, b.icon, b.color ORDER BY total DESC, b.name ASC"
    return db.statsDao().bookSums(SimpleSQLiteQuery(sql, args.toTypedArray())).map {
      BookSum(it.bookId, it.name, it.icon, it.color, it.cents)
    }
  }

  suspend fun byDay(filter: StatsFilter): List<DaySum> {
    val args = ArrayList<Any?>()
    val where = buildWhere(filter, args, "t.")
    val sql =
      "SELECT t.day_key AS day_key, SUM(t.amount_cents) AS total FROM txn t WHERE $where " +
        "GROUP BY t.day_key ORDER BY t.day_key ASC"
    val raw = db.statsDao().daySums(SimpleSQLiteQuery(sql, args.toTypedArray())).map {
      DaySum(it.dayKey, it.cents)
    }
    return fillDays(filter, raw)
  }

  suspend fun byBucket(filter: StatsFilter, granularity: BucketGranularity): List<BucketSum> =
    when (granularity) {
      BucketGranularity.DAY ->
        byDay(filter).map { BucketSum(key = it.dayKey, label = dayLabel(it.dayKey), cents = it.cents) }
      BucketGranularity.MONTH ->
        queryBuckets(filter, "substr(t.day_key, 1, 7)", granularity)
      BucketGranularity.WEEK -> {
        val target = filter.weekStart % 7
        val expr =
          "date(t.day_key, '-' || ((CAST(strftime('%w', t.day_key) AS INTEGER) - $target + 7) % 7) || ' days')"
        queryBuckets(filter, expr, granularity)
      }
    }

  suspend fun topDays(filter: StatsFilter, n: Int): List<DaySum> =
    byDay(filter)
      .filter { it.cents > 0 }
      .sortedWith(compareByDescending<DaySum> { it.cents }.thenBy { it.dayKey })
      .take(n)

  suspend fun dailyStats(filter: StatsFilter): DailyStats {
    var total = 0L
    var days = 0
    var max = 0L
    var maxDayKey = ""
    for (day in byDay(filter)) {
      if (day.cents <= 0) {
        continue
      }
      total += day.cents
      days += 1
      if (day.cents > max) {
        max = day.cents
        maxDayKey = day.dayKey
      }
    }
    val avg = if (days > 0) Math.floorDiv(total, days.toLong()) else 0L
    return DailyStats(totalCents = total, avgCents = avg, maxCents = max, maxDayKey = maxDayKey, days = days)
  }

  /** 图例：前 5 个分类 + “其他”，其他金额为剩余分类之和。 */
  suspend fun categoryLegend(filter: StatsFilter): List<CategorySum> {
    val all = byCategory(filter)
    if (all.size <= 5) {
      return all
    }
    val result = all.take(5).toMutableList()
    val otherCents = all.drop(5).sumOf { it.cents }
    if (otherCents > 0) {
      result.add(CategorySum(categoryId = "__other__", name = "其他", icon = "ic_cat_other", cents = otherCents))
    }
    return result
  }

  private suspend fun queryBuckets(
    filter: StatsFilter,
    keyExpr: String,
    granularity: BucketGranularity,
  ): List<BucketSum> {
    val args = ArrayList<Any?>()
    val where = buildWhere(filter, args, "t.")
    val sql =
      "SELECT $keyExpr AS bucket_key, SUM(t.amount_cents) AS total FROM txn t WHERE $where " +
        "GROUP BY bucket_key ORDER BY bucket_key ASC"
    return db.statsDao().bucketSums(SimpleSQLiteQuery(sql, args.toTypedArray())).map {
      BucketSum(
        key = it.key,
        label = if (granularity == BucketGranularity.MONTH) monthLabel(it.key) else weekLabel(it.key),
        cents = it.cents,
      )
    }
  }

  private fun buildWhere(filter: StatsFilter, args: MutableList<Any?>, prefix: String): String {
    val where = StringBuilder("t.deleted_at IS NULL")
    if (filter.startMs > 0) {
      where.append(" AND ${prefix}day_key >= ?")
      args.add(DateUtil.dayKey(filter.startMs))
    }
    if (filter.endMs > 0) {
      where.append(" AND ${prefix}day_key <= ?")
      args.add(DateUtil.dayKey(filter.endMs))
    }
    if (filter.bookIds.isNotEmpty()) {
      where.append(" AND ${prefix}book_id IN (${marks(filter.bookIds.size)})")
      args.addAll(filter.bookIds)
    }
    if (filter.excludeBookIds.isNotEmpty()) {
      where.append(" AND ${prefix}book_id NOT IN (${marks(filter.excludeBookIds.size)})")
      args.addAll(filter.excludeBookIds)
    }
    where.append(" AND ${prefix}book_id NOT IN (SELECT id FROM book WHERE archived = 1)")
    return where.toString()
  }

  private fun fillDays(filter: StatsFilter, raw: List<DaySum>): List<DaySum> {
    if (filter.startMs <= 0 || filter.endMs <= 0) {
      return raw
    }
    val startKey = DateUtil.dayKey(filter.startMs)
    val endKey = DateUtil.dayKey(filter.endMs)
    val start = DateUtil.parseDayKey(startKey)
    val end = DateUtil.parseDayKey(endKey)
    val totalDays = java.time.temporal.ChronoUnit.DAYS.between(start, end).toInt() + 1
    if (totalDays <= 0 || totalDays > 400) {
      return raw
    }
    val lookup = raw.associate { it.dayKey to it.cents }
    return (0 until totalDays).map { offset ->
      val key = DateUtil.dayKey(start.plusDays(offset.toLong()))
      DaySum(dayKey = key, cents = lookup[key] ?: 0L)
    }
  }

  private fun marks(count: Int): String = List(count) { "?" }.joinToString(", ")

  private fun dayLabel(dayKey: String): String {
    val parts = dayKey.split("-")
    if (parts.size != 3) {
      return dayKey
    }
    return "${parts[1].toIntOrNull() ?: parts[1]}/${parts[2].toIntOrNull() ?: parts[2]}"
  }

  private fun weekLabel(dayKey: String): String = dayLabel(dayKey) + "周"

  private fun monthLabel(monthKey: String): String {
    val parts = monthKey.split("-")
    if (parts.size != 2) {
      return monthKey
    }
    return "${parts[1].toIntOrNull() ?: parts[1]}月"
  }
}
