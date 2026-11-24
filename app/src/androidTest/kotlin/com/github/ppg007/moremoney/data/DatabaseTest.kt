package com.github.ppg007.moremoney.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.SeedData
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.BudgetRepository
import com.github.ppg007.moremoney.data.repository.TxnRepository
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Room DAO / 种子 / Schema 例外测试。
 *
 * 断言 `book` 表只有 9 个普通列，且部分唯一索引 `idx_book_default` 存在。
 */
@RunWith(AndroidJUnit4::class)
class DatabaseTest {
  private lateinit var db: MoreMoneyDatabase

  @Before
  fun setUp() {
    val context: Context = ApplicationProvider.getApplicationContext()
    db =
      Room.inMemoryDatabaseBuilder(context, MoreMoneyDatabase::class.java)
        .addCallback(MoreMoneyDatabase.CALLBACK)
        .allowMainThreadQueries()
        .build()
    runBlocking { SeedData.ensureSeeded(db) }
  }

  @After
  fun tearDown() {
    db.close()
  }

  @Test
  fun seedIsIdempotent() =
    runBlocking {
      SeedData.ensureSeeded(db)
      SeedData.ensureSeeded(db)
      assertEquals(3, db.bookDao().countAll())
      assertEquals(6, db.categoryDao().listGroups().size)
      assertEquals(10, db.categoryDao().countAll())
      assertEquals("1", db.appMetaDao().get("seed_version"))
      assertEquals("2", db.appMetaDao().get("schema_version"))
      assertFalse(tableExists("member"))
    }

  @Test
  fun bookTableHasExactlyNineNormalColumns() {
    val cursor = db.openHelper.writableDatabase.query("PRAGMA table_info(`book`)")
    val names = ArrayList<String>()
    try {
      cursor.moveToFirst()
      while (!cursor.isAfterLast) {
        names.add(cursor.getString(cursor.getColumnIndexOrThrow("name")))
        cursor.moveToNext()
      }
    } finally {
      cursor.close()
    }
    assertEquals(
      listOf("id", "name", "icon", "color", "is_default", "sort", "archived", "created_at", "updated_at"),
      names,
    )
    assertFalse(names.contains("is_private"))
    assertFalse(names.contains("pwd_hash"))
    assertFalse(names.contains("pwd_salt"))
    assertFalse(names.contains("pwd_iter"))
  }

  @Test
  fun otherTablesKeepExpectedIndexes() {
    val txnIndices = indexNames("txn")
    assertTrue(txnIndices.contains("idx_txn_book_day"))
    assertTrue(txnIndices.contains("idx_txn_day"))
    assertTrue(txnIndices.contains("idx_txn_category"))
    assertTrue(indexNames("category").contains("idx_category_group"))
    assertTrue(indexNames("budget").contains("idx_budget_book_period"))
  }

  @Test
  fun txnHasNoMemberColumn() {
    val columns = columnNames("txn")
    assertFalse(columns.contains("member_id"))
  }

  @Test
  fun partialDefaultBookIndexExists() {
    assertTrue(indexNames("book").contains("idx_book_default"))
  }

  @Test
  fun defaultBookStaysUnique() =
    runBlocking {
      val repository = BookRepository(db)
      repository.setDefault("book_travel")
      repository.setDefault("book_repair")
      val books = db.bookDao().list()
      assertEquals(1, books.count { it.isDefault })
      assertEquals("book_repair", books.first { it.isDefault }.id)
    }

  @Test
  fun softDeleteAndRestoreRoundTrip() =
    runBlocking {
      val repository = TxnRepository(db)
      val now = System.currentTimeMillis()
      val txn =
        TxnEntity(
          id = "txn_soft",
          bookId = "book_daily",
          categoryId = "cat_food",
          amountCents = 3200,
          occurredAt = now,
          dayKey = "2026-11-09",
          note = "午餐",
          createdAt = now,
          updatedAt = now,
        )
      repository.insert(txn)
      assertEquals(1, repository.listActive().size)
      repository.softDelete(txn.id)
      assertEquals(0, repository.listActive().size)
      repository.restore(txn.id)
      assertEquals(1, repository.listActive().size)
      assertEquals(3200L, repository.listActive().first().amountCents)
    }

  @Test
  fun purgeRemovesOnlyExpiredSoftDeletes() =
    runBlocking {
      val repository = TxnRepository(db)
      val now = System.currentTimeMillis()
      repository.insert(
        TxnEntity(
          id = "txn_old",
          bookId = "book_daily",
          categoryId = "cat_food",
          amountCents = 100,
          occurredAt = now,
          dayKey = "2026-11-09",
          note = "",
          createdAt = now,
          updatedAt = now,
          deletedAt = now - 31L * 24 * 60 * 60 * 1000,
        )
      )
      repository.purgeExpired()
      assertEquals(0, db.txnDao().countAll())
    }

  @Test
  fun budgetUpsertKeepsExistingId() =
    runBlocking {
      val repository = BudgetRepository(db)
      repository.upsert("book_daily", "2026-11", 300_000)
      val first = repository.get("book_daily", "2026-11")
      assertNotNull(first)
      assertEquals("budget_book_daily_2026-11", first!!.id)
      repository.upsert("book_daily", "2026-11", 400_000)
      val second = repository.get("book_daily", "2026-11")
      assertEquals(first.id, second!!.id)
      assertEquals(400_000L, second.amountCents)
      assertEquals(1, repository.listByPeriod("2026-11").size)
    }

  @Test
  fun deleteBookWithTransactionsIsRejected() =
    runBlocking {
      val repository = BookRepository(db)
      val book = db.bookDao().get("book_daily")!!
      db.txnDao().insert(
        TxnEntity(
          id = "txn_guard",
          bookId = book.id,
          categoryId = "cat_food",
          amountCents = 100,
          occurredAt = System.currentTimeMillis(),
          dayKey = "2026-11-09",
          note = "",
          createdAt = System.currentTimeMillis(),
          updatedAt = System.currentTimeMillis(),
        )
      )
      var failed = false
      try {
        repository.delete(book)
      } catch (error: IllegalStateException) {
        failed = true
      }
      assertTrue(failed)
      assertNotNull(db.bookDao().get(book.id))
    }

  private fun tableExists(table: String): Boolean {
    val cursor = db.openHelper.writableDatabase.query(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      arrayOf(table),
    )
    return try {
      cursor.moveToFirst()
    } finally {
      cursor.close()
    }
  }

  private fun columnNames(table: String): List<String> {
    val cursor = db.openHelper.writableDatabase.query("PRAGMA table_info(`$table`)")
    val names = ArrayList<String>()
    try {
      cursor.moveToFirst()
      while (!cursor.isAfterLast) {
        names.add(cursor.getString(cursor.getColumnIndexOrThrow("name")))
        cursor.moveToNext()
      }
    } finally {
      cursor.close()
    }
    return names
  }

  private fun indexNames(table: String): List<String> {
    val cursor = db.openHelper.writableDatabase.query("PRAGMA index_list(`$table`)")
    val names = ArrayList<String>()
    try {
      cursor.moveToFirst()
      while (!cursor.isAfterLast) {
        names.add(cursor.getString(cursor.getColumnIndexOrThrow("name")))
        cursor.moveToNext()
      }
    } finally {
      cursor.close()
    }
    return names
  }
}
