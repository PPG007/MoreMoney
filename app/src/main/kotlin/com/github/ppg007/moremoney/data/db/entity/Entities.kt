package com.github.ppg007.moremoney.data.db.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * 业务数据表（schema v2）。
 *
 * 无 `member` 表；`book` 表不包含
 * `is_private` / `pwd_hash` / `pwd_salt` / `pwd_iter` 四个私密列。
 * 金额列一律以 `_cents` 结尾并使用 INTEGER（整数分）。
 */
@Entity(tableName = "book")
data class BookEntity(
  @PrimaryKey val id: String,
  val name: String,
  val icon: String,
  val color: String,
  @ColumnInfo(name = "is_default", defaultValue = "0") val isDefault: Boolean = false,
  @ColumnInfo(defaultValue = "0") val sort: Int = 0,
  @ColumnInfo(defaultValue = "0") val archived: Boolean = false,
  @ColumnInfo(name = "created_at") val createdAt: Long,
  @ColumnInfo(name = "updated_at") val updatedAt: Long,
)

@Entity(tableName = "category_group")
data class CategoryGroupEntity(
  @PrimaryKey val id: String,
  val name: String,
  @ColumnInfo(defaultValue = "0") val sort: Int = 0,
  @ColumnInfo(name = "is_system", defaultValue = "0") val isSystem: Boolean = false,
)

@Entity(
  tableName = "category",
  indices = [Index(value = ["group_id"], name = "idx_category_group")],
)
data class CategoryEntity(
  @PrimaryKey val id: String,
  @ColumnInfo(name = "group_id") val groupId: String,
  val name: String,
  val icon: String,
  val color: String,
  @ColumnInfo(defaultValue = "''") val pinyin: String = "",
  @ColumnInfo(defaultValue = "0") val sort: Int = 0,
  @ColumnInfo(defaultValue = "0") val archived: Boolean = false,
  @ColumnInfo(name = "created_at") val createdAt: Long,
)

@Entity(
  tableName = "txn",
  indices = [
    Index(value = ["book_id", "day_key"], name = "idx_txn_book_day"),
    Index(value = ["day_key"], name = "idx_txn_day"),
    Index(value = ["category_id"], name = "idx_txn_category"),
  ],
)
data class TxnEntity(
  @PrimaryKey val id: String,
  @ColumnInfo(name = "book_id") val bookId: String,
  @ColumnInfo(name = "category_id") val categoryId: String,
  @ColumnInfo(name = "amount_cents") val amountCents: Long,
  @ColumnInfo(name = "occurred_at") val occurredAt: Long,
  @ColumnInfo(name = "day_key") val dayKey: String,
  @ColumnInfo(defaultValue = "''") val note: String = "",
  @ColumnInfo(name = "created_at") val createdAt: Long,
  @ColumnInfo(name = "updated_at") val updatedAt: Long,
  @ColumnInfo(name = "deleted_at") val deletedAt: Long? = null,
)

@Entity(
  tableName = "budget",
  indices = [Index(value = ["book_id", "period"], unique = true, name = "idx_budget_book_period")],
)
data class BudgetEntity(
  @PrimaryKey val id: String,
  @ColumnInfo(name = "book_id") val bookId: String,
  val period: String,
  @ColumnInfo(name = "amount_cents") val amountCents: Long,
  @ColumnInfo(name = "updated_at") val updatedAt: Long,
)

@Entity(tableName = "app_meta")
data class AppMetaEntity(
  @PrimaryKey val key: String,
  val value: String,
)
