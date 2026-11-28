package com.github.ppg007.moremoney.data

import android.content.Context
import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.sqlite.db.SupportSQLiteOpenHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.models.BudgetCycle
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * 数据库迁移：v1 → v2 删除成员；v2 → v3 预算改为每账本一条配置。
 *
 * 手动按历史 schema JSON 建库后交给 Room 打开；Room 会执行迁移并校验最终 schema。
 */
@RunWith(AndroidJUnit4::class)
class MigrationTest {
  @Test
  fun migrate1To3RemovesMemberAndKeepsTransactions() {
    val context: Context = ApplicationProvider.getApplicationContext()
    context.deleteDatabase(TEST_DB)

    val config =
      SupportSQLiteOpenHelper.Configuration.builder(context)
        .name(TEST_DB)
        .callback(
          object : SupportSQLiteOpenHelper.Callback(1) {
            override fun onCreate(db: SupportSQLiteDatabase) {
              createSchema(context, db, 1)
            }

            override fun onUpgrade(db: SupportSQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
          }
        )
        .build()
    val helper = FrameworkSQLiteOpenHelperFactory().create(config)
    val db = helper.writableDatabase
    db.execSQL(
      "INSERT INTO book (id, name, icon, color, is_default, sort, archived, created_at, updated_at) " +
        "VALUES ('b1', 'B', 'ic_book_daily', '#2A78D6', 1, 0, 0, 1, 1)"
    )
    db.execSQL(
      "INSERT INTO member (id, name, initial, color, is_default, sort, archived) " +
        "VALUES ('m1', 'M', 'M', '#2A78D6', 1, 0, 0)"
    )
    db.execSQL(
      "INSERT INTO txn (id, book_id, category_id, member_id, amount_cents, occurred_at, day_key, " +
        "note, created_at, updated_at, deleted_at) " +
        "VALUES ('t1', 'b1', 'c1', 'm1', 3200, 1000, '2026-11-09', '午餐', 1, 1, NULL)"
    )
    db.close()
    helper.close()

    val room = MoreMoneyDatabase.create(context, TEST_DB)
    try {
      val books = runBlocking { room.bookDao().list() }
      assertEquals(1, books.size)
      assertEquals("b1", books.first().id)

      val txns = runBlocking { room.txnDao().listActive() }
      assertEquals(1, txns.size)
      assertEquals("t1", txns.first().id)
      assertEquals("b1", txns.first().bookId)
      assertEquals("c1", txns.first().categoryId)
      assertEquals(3200L, txns.first().amountCents)
      assertEquals("午餐", txns.first().note)

      val raw = room.openHelper.readableDatabase
      val memberTable = raw.query("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'member'")
      assertFalse(memberTable.moveToFirst())
      memberTable.close()

      val columns = raw.query("PRAGMA table_info(`txn`)")
      var hasMemberColumn = false
      while (columns.moveToNext()) {
        if (columns.getString(columns.getColumnIndexOrThrow("name")) == "member_id") {
          hasMemberColumn = true
        }
      }
      columns.close()
      assertFalse(hasMemberColumn)

      val metaCursor = raw.query("SELECT value FROM app_meta WHERE key = 'schema_version'")
      assertTrue(metaCursor.moveToFirst())
      assertEquals("3", metaCursor.getString(0))
      metaCursor.close()
    } finally {
      room.close()
      context.deleteDatabase(TEST_DB)
    }
  }

  @Test
  fun migrate2To3CollapsesBudgetsToLatestPerBook() {
    val context: Context = ApplicationProvider.getApplicationContext()
    context.deleteDatabase(TEST_DB)

    val config =
      SupportSQLiteOpenHelper.Configuration.builder(context)
        .name(TEST_DB)
        .callback(
          object : SupportSQLiteOpenHelper.Callback(2) {
            override fun onCreate(db: SupportSQLiteDatabase) {
              createSchema(context, db, 2)
            }

            override fun onUpgrade(db: SupportSQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
          }
        )
        .build()
    val helper = FrameworkSQLiteOpenHelperFactory().create(config)
    val db = helper.writableDatabase
    db.execSQL(
      "INSERT INTO book (id, name, icon, color, is_default, sort, archived, created_at, updated_at) " +
        "VALUES ('b1', 'B1', 'ic_book_daily', '#2A78D6', 1, 0, 0, 1, 1)"
    )
    db.execSQL(
      "INSERT INTO book (id, name, icon, color, is_default, sort, archived, created_at, updated_at) " +
        "VALUES ('b2', 'B2', 'ic_book_daily', '#EB6834', 0, 1, 0, 1, 1)"
    )
    db.execSQL(
      "INSERT INTO budget (id, book_id, period, amount_cents, updated_at) " +
        "VALUES ('budget_old', 'b1', '2026-10', 100_000, 10)"
    )
    db.execSQL(
      "INSERT INTO budget (id, book_id, period, amount_cents, updated_at) " +
        "VALUES ('budget_new', 'b1', '2026-11', 200_000, 20)"
    )
    db.execSQL(
      "INSERT INTO budget (id, book_id, period, amount_cents, updated_at) " +
        "VALUES ('budget_b2', 'b2', '2026-11', 300_000, 30)"
    )
    db.close()
    helper.close()

    val room = MoreMoneyDatabase.create(context, TEST_DB)
    try {
      val budgets = runBlocking { room.budgetDao().listAll() }.associateBy { it.bookId }
      assertEquals(2, budgets.size)
      assertEquals("budget_new", budgets["b1"]?.id)
      assertEquals(200_000L, budgets["b1"]?.amountCents)
      assertEquals(BudgetCycle.MONTH, budgets["b1"]?.cycle)
      assertEquals(300_000L, budgets["b2"]?.amountCents)
      assertEquals(BudgetCycle.MONTH, budgets["b2"]?.cycle)
    } finally {
      room.close()
      context.deleteDatabase(TEST_DB)
    }
  }

  private fun createSchema(context: Context, db: SupportSQLiteDatabase, version: Int) {
    // schema 作为 androidTest assets 打包在测试 APK 中，必须用测试上下文读取。
    val testAssets = InstrumentationRegistry.getInstrumentation().context.assets
    val json =
      JSONObject(
        testAssets
          .open("com.github.ppg007.moremoney.data.db.MoreMoneyDatabase/$version.json")
          .bufferedReader()
          .use { it.readText() }
      )
    val entities = json.getJSONObject("database").getJSONArray("entities")
    for (i in 0 until entities.length()) {
      val entity = entities.getJSONObject(i)
      val table = entity.getString("tableName")
      db.execSQL(entity.getString("createSql").replace("\${TABLE_NAME}", table))
      val indices = entity.optJSONArray("indices") ?: continue
      for (j in 0 until indices.length()) {
        db.execSQL(indices.getJSONObject(j).getString("createSql").replace("\${TABLE_NAME}", table))
      }
    }
  }

  private companion object {
    const val TEST_DB = "migration-test"
  }
}
