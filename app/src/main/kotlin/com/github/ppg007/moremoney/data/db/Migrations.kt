package com.github.ppg007.moremoney.data.db

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

/**
 * v1 → v2：移除成员管理。
 *
 * - 删除 `member` 表；
 * - 重建 `txn` 表，去掉 `member_id` 列；
 * - 保留全部流水、金额、日期、备注与软删状态；
 * - 把 `app_meta.schema_version` 更新为 2。
 */
val MIGRATION_1_2 =
  object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
      // 部分唯一索引不在 Room schema JSON 中，迁移校验前先移除，onOpen 会重新创建。
      db.execSQL("DROP INDEX IF EXISTS `idx_book_default`")
      db.execSQL("DROP TABLE IF EXISTS member")

      db.execSQL(
        """
        CREATE TABLE IF NOT EXISTS `txn_new` (
          `id` TEXT NOT NULL,
          `book_id` TEXT NOT NULL,
          `category_id` TEXT NOT NULL,
          `amount_cents` INTEGER NOT NULL,
          `occurred_at` INTEGER NOT NULL,
          `day_key` TEXT NOT NULL,
          `note` TEXT NOT NULL DEFAULT '',
          `created_at` INTEGER NOT NULL,
          `updated_at` INTEGER NOT NULL,
          `deleted_at` INTEGER,
          PRIMARY KEY(`id`)
        )
        """.trimIndent()
      )
      db.execSQL(
        """
        INSERT INTO `txn_new` (`id`, `book_id`, `category_id`, `amount_cents`, `occurred_at`, `day_key`,
          `note`, `created_at`, `updated_at`, `deleted_at`)
        SELECT `id`, `book_id`, `category_id`, `amount_cents`, `occurred_at`, `day_key`,
          `note`, `created_at`, `updated_at`, `deleted_at`
        FROM `txn`
        """.trimIndent()
      )
      db.execSQL("DROP TABLE `txn`")
      db.execSQL("ALTER TABLE `txn_new` RENAME TO `txn`")

      db.execSQL("CREATE INDEX IF NOT EXISTS `idx_txn_book_day` ON `txn` (`book_id`, `day_key`)")
      db.execSQL("CREATE INDEX IF NOT EXISTS `idx_txn_day` ON `txn` (`day_key`)")
      db.execSQL("CREATE INDEX IF NOT EXISTS `idx_txn_category` ON `txn` (`category_id`)")

      db.execSQL("INSERT OR REPLACE INTO `app_meta` (`key`, `value`) VALUES ('schema_version', '2')")
    }
  }

/**
 * v2 → v3：预算改为“一个账本一条配置”。
 *
 * - 重建 `budget` 表，用 `cycle` 替代 `period`，唯一索引改为 `book_id`；
 * - 旧数据按月预算处理：同一账本有多条时，保留 `updated_at` 最新的一条；
 * - 设置后由应用按周期自动重复与折算，不再逐月保存。
 */
val MIGRATION_2_3 =
  object : Migration(2, 3) {
    override fun migrate(db: SupportSQLiteDatabase) {
      // 部分唯一索引不在 Room schema JSON 中，迁移校验前先移除，onOpen 会重新创建。
      db.execSQL("DROP INDEX IF EXISTS `idx_book_default`")

      db.execSQL(
        """
        CREATE TABLE IF NOT EXISTS `budget_new` (
          `id` TEXT NOT NULL,
          `book_id` TEXT NOT NULL,
          `cycle` TEXT NOT NULL,
          `amount_cents` INTEGER NOT NULL,
          `updated_at` INTEGER NOT NULL,
          PRIMARY KEY(`id`)
        )
        """.trimIndent()
      )
      db.execSQL(
        """
        INSERT INTO `budget_new` (`id`, `book_id`, `cycle`, `amount_cents`, `updated_at`)
        SELECT b.`id`, b.`book_id`, 'MONTH', b.`amount_cents`, b.`updated_at`
        FROM `budget` b
        WHERE b.`amount_cents` > 0
          AND b.`id` = (
            SELECT b2.`id` FROM `budget` b2
            WHERE b2.`book_id` = b.`book_id` AND b2.`amount_cents` > 0
            ORDER BY b2.`updated_at` DESC, b2.`period` DESC, b2.`id` DESC
            LIMIT 1
          )
        """.trimIndent()
      )
      db.execSQL("DROP TABLE `budget`")
      db.execSQL("ALTER TABLE `budget_new` RENAME TO `budget`")
      db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS `idx_budget_book` ON `budget` (`book_id`)")

      db.execSQL("INSERT OR REPLACE INTO `app_meta` (`key`, `value`) VALUES ('schema_version', '3')")
    }
  }
