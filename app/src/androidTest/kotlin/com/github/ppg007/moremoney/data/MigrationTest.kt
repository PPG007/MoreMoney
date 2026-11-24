package com.github.ppg007.moremoney.data

import android.content.Context
import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.sqlite.db.SupportSQLiteOpenHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * v1 → v2：删除 member 表与 txn.member_id，同时保留流水数据。
 *
 * 手动按 1.json 建库后交给 Room 打开；Room 会执行迁移并校验最终 schema。
 */
@RunWith(AndroidJUnit4::class)
class MigrationTest {
  @Test
  fun migrate1To2RemovesMemberAndKeepsTransactions() {
    val context: Context = ApplicationProvider.getApplicationContext()
    context.deleteDatabase(TEST_DB)

    val config =
      SupportSQLiteOpenHelper.Configuration.builder(context)
        .name(TEST_DB)
        .callback(
          object : SupportSQLiteOpenHelper.Callback(1) {
            override fun onCreate(db: SupportSQLiteDatabase) {
              createV1Schema(context, db)
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
      assertEquals("2", metaCursor.getString(0))
      metaCursor.close()
    } finally {
      room.close()
      context.deleteDatabase(TEST_DB)
    }
  }

  private fun createV1Schema(context: Context, db: SupportSQLiteDatabase) {
    // schema 作为 androidTest assets 打包在测试 APK 中，必须用测试上下文读取。
    val testAssets = InstrumentationRegistry.getInstrumentation().context.assets
    val json =
      JSONObject(
        testAssets
          .open("com.github.ppg007.moremoney.data.db.MoreMoneyDatabase/1.json")
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
