package com.github.ppg007.moremoney.data.db.dao

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.RawQuery
import androidx.sqlite.db.SupportSQLiteQuery
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity

data class CategorySumRow(
  @ColumnInfo(name = "category_id") val categoryId: String,
  @ColumnInfo(name = "category_name") val name: String,
  @ColumnInfo(name = "category_icon") val icon: String,
  @ColumnInfo(name = "category_color") val color: String,
  @ColumnInfo(name = "total") val cents: Long,
)

data class BookSumRow(
  @ColumnInfo(name = "book_id") val bookId: String,
  @ColumnInfo(name = "book_name") val name: String,
  @ColumnInfo(name = "book_icon") val icon: String,
  @ColumnInfo(name = "book_color") val color: String,
  @ColumnInfo(name = "total") val cents: Long,
)

data class DaySumRow(
  @ColumnInfo(name = "day_key") val dayKey: String,
  @ColumnInfo(name = "total") val cents: Long,
)

data class BucketSumRow(
  @ColumnInfo(name = "bucket_key") val key: String,
  @ColumnInfo(name = "total") val cents: Long,
)

/**
 * 统计聚合查询。动态条件用 [SupportSQLiteQuery] 构造，页面不直接接触 SQL。
 *
 * 金额聚合全部返回整数分，禁止 `AVG` 等浮点返回；日均值由 [StatsService] 用整数除法计算。
 */
@Dao
interface StatsDao {
  @RawQuery(observedEntities = [TxnEntity::class])
  suspend fun sum(query: SupportSQLiteQuery): Long

  @RawQuery(observedEntities = [TxnEntity::class, CategoryEntity::class])
  suspend fun categorySums(query: SupportSQLiteQuery): List<CategorySumRow>

  @RawQuery(observedEntities = [TxnEntity::class, BookEntity::class])
  suspend fun bookSums(query: SupportSQLiteQuery): List<BookSumRow>

  @RawQuery(observedEntities = [TxnEntity::class])
  suspend fun daySums(query: SupportSQLiteQuery): List<DaySumRow>

  @RawQuery(observedEntities = [TxnEntity::class])
  suspend fun bucketSums(query: SupportSQLiteQuery): List<BucketSumRow>
}
