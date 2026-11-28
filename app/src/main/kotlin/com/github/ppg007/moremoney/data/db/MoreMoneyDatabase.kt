package com.github.ppg007.moremoney.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.github.ppg007.moremoney.data.db.dao.AppMetaDao
import com.github.ppg007.moremoney.data.db.dao.BookDao
import com.github.ppg007.moremoney.data.db.dao.BudgetDao
import com.github.ppg007.moremoney.data.db.dao.CategoryDao
import com.github.ppg007.moremoney.data.db.dao.StatsDao
import com.github.ppg007.moremoney.data.db.dao.TxnDao
import com.github.ppg007.moremoney.data.db.entity.AppMetaEntity
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity

/**
 * MoreMoney 数据库，version = 3。
 *
 * v2 删除 `member` 表与 `txn.member_id`，迁移见 [MIGRATION_1_2]；
 * v3 预算改为每账本一条“周期 + 金额”，迁移见 [MIGRATION_2_3]；
 * `book` 表省略 4 个私密列。
 * `idx_book_default` 是部分唯一索引，Room 的 `@Index` 不支持 `WHERE` 子句，
 * 因此放在 [CALLBACK] 的 `onCreate` / `onOpen` 中创建；Room 导出的 schema JSON 不包含它。
 */
@Database(
  entities = [
    BookEntity::class,
    CategoryGroupEntity::class,
    CategoryEntity::class,
    TxnEntity::class,
    BudgetEntity::class,
    AppMetaEntity::class,
  ],
  version = 3,
  exportSchema = true,
)
abstract class MoreMoneyDatabase : RoomDatabase() {
  abstract fun bookDao(): BookDao

  abstract fun categoryDao(): CategoryDao

  abstract fun txnDao(): TxnDao

  abstract fun budgetDao(): BudgetDao

  abstract fun appMetaDao(): AppMetaDao

  abstract fun statsDao(): StatsDao

  companion object {
    const val DB_NAME = "moremoney.db"

    val CALLBACK =
      object : Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
          super.onCreate(db)
          createPartialIndexes(db)
        }

        override fun onOpen(db: SupportSQLiteDatabase) {
          super.onOpen(db)
          // 迁移会先删除该索引以通过 Room schema 校验，这里统一补回。
          createPartialIndexes(db)
        }

        private fun createPartialIndexes(db: SupportSQLiteDatabase) {
          // 部分唯一索引：同一时刻只允许一个默认账本。
          db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS idx_book_default ON book(is_default) WHERE is_default = 1")
        }
      }

    fun create(context: Context, name: String = DB_NAME): MoreMoneyDatabase =
      Room.databaseBuilder(context.applicationContext, MoreMoneyDatabase::class.java, name)
        .addCallback(CALLBACK)
        .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
        .build()
  }
}
