package com.github.ppg007.moremoney.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.SeedData
import com.github.ppg007.moremoney.data.db.entity.AppMetaEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.BudgetRepository
import com.github.ppg007.moremoney.data.repository.TxnRepository
import com.github.ppg007.moremoney.models.BudgetCycle
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
      assertEquals(18, db.categoryDao().countAll())
      assertEquals("2", db.appMetaDao().get("seed_version"))
      assertEquals("3", db.appMetaDao().get("schema_version"))
      assertFalse(tableExists("member"))
    }

  @Test
  fun builtInCategoriesMatchV2List() =
    runBlocking {
      val names = db.categoryDao().list().filter { !it.archived }.map { it.name }.toSet()
      assertEquals(
        setOf(
          "饮食", "电费", "日用", "交通", "社交", "住房物业", "停车费", "洗车", "礼物",
          "通信", "工作", "服饰", "娱乐", "美容", "医疗", "税金", "教育", "旅行",
        ),
        names,
      )
    }

  @Test
  fun seedV2MigratesLegacyCategoryNames() =
    runBlocking {
      val context: Context = ApplicationProvider.getApplicationContext()
      val legacyDb =
        Room.inMemoryDatabaseBuilder(context, MoreMoneyDatabase::class.java)
          .addCallback(MoreMoneyDatabase.CALLBACK)
          .allowMainThreadQueries()
          .build()
      try {
        legacyDb.appMetaDao().put(AppMetaEntity("seed_version", "1"))
        legacyDb.categoryDao().insertGroup(CategoryGroupEntity("group_food", "餐饮", 0, true))
        legacyDb.categoryDao().insertGroup(CategoryGroupEntity("group_other", "其他", 5, true))
        legacyDb.categoryDao().insert(
          CategoryEntity(
            id = "cat_food", groupId = "group_food", name = "餐饮", icon = "ic_cat_food",
            color = "#EB6834", pinyin = "canyin", sort = 0, archived = false, createdAt = 1,
          )
        )
        legacyDb.categoryDao().insert(
          CategoryEntity(
            id = "cat_other", groupId = "group_other", name = "其他", icon = "ic_cat_other",
            color = "#B8AAB1", pinyin = "qita", sort = 3, archived = false, createdAt = 1,
          )
        )

        SeedData.ensureSeeded(legacyDb)

        val food = legacyDb.categoryDao().get("cat_food")
        assertNotNull(food)
        assertEquals("饮食", food!!.name)
        assertEquals("yinshi", food.pinyin)
        assertTrue(legacyDb.categoryDao().get("cat_other")!!.archived)
        assertEquals(18, legacyDb.categoryDao().list().count { !it.archived })
      } finally {
        legacyDb.close()
      }
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
    assertTrue(indexNames("budget").contains("idx_budget_book"))
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
      repository.upsert("book_daily", BudgetCycle.MONTH, 300_000)
      val first = repository.get("book_daily")
      assertNotNull(first)
      assertEquals("budget_book_daily", first!!.id)
      assertEquals(BudgetCycle.MONTH, first.cycle)
      repository.upsert("book_daily", BudgetCycle.YEAR, 400_000)
      val second = repository.get("book_daily")
      assertEquals(first.id, second!!.id)
      assertEquals(BudgetCycle.YEAR, second.cycle)
      assertEquals(400_000L, second.amountCents)
      assertEquals(1, repository.listAll().size)
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
