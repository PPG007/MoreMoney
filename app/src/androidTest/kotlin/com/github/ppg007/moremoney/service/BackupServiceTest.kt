package com.github.ppg007.moremoney.service

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.SeedData
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.BudgetRepository
import com.github.ppg007.moremoney.data.repository.CategoryRepository
import com.github.ppg007.moremoney.data.repository.TxnRepository
import com.github.ppg007.moremoney.state.SettingsService
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.security.MessageDigest
import java.util.Base64

/** 备份导出/恢复：只处理普通账本，旧备份中的私密账本与 PRIVATE 段跳过并提示。 */
@RunWith(AndroidJUnit4::class)
class BackupServiceTest {
  private lateinit var db: MoreMoneyDatabase
  private lateinit var service: BackupService
  private lateinit var txnRepository: TxnRepository

  @Before
  fun setUp() {
    val context: Context = ApplicationProvider.getApplicationContext()
    db =
      Room.inMemoryDatabaseBuilder(context, MoreMoneyDatabase::class.java)
        .addCallback(MoreMoneyDatabase.CALLBACK)
        .allowMainThreadQueries()
        .build()
    runBlocking { SeedData.ensureSeeded(db) }
    val bookRepository = BookRepository(db)
    val categoryRepository = CategoryRepository(db)
    txnRepository = TxnRepository(db)
    val budgetRepository = BudgetRepository(db)
    service =
      BackupService(
        db,
        bookRepository,
        categoryRepository,
        txnRepository,
        budgetRepository,
        SettingsService(context),
      )
  }

  @After
  fun tearDown() {
    db.close()
  }

  @Test
  fun exportsNormalBackupWithPlaceholderPrivateColumns() =
    runBlocking {
      val now = System.currentTimeMillis()
      txnRepository.insert(
        TxnEntity(
          id = "txn_export",
          bookId = "book_daily",
          categoryId = "cat_food",
          amountCents = 3200,
          occurredAt = now,
          dayKey = "2026-11-09",
          note = "午餐",
          createdAt = now,
          updatedAt = now,
        )
      )
      val export = service.buildExport(now)
      assertTrue(export.text.startsWith(BackupFormat.MAGIC))
      assertTrue(export.text.contains("format=1"))
      assertTrue(export.text.contains("schemaVersion=3"))
      assertFalse(export.text.contains("\nPRIVATE\t"))
      assertFalse(export.text.contains("\nMEMBER\t"))
      assertFalse(export.text.contains("members="))
      val txnLine = export.text.lines().first { it.startsWith("TXN\t") }
      // TXN 行含类型在内共 10 段（9 列），不再包含 member。
      assertEquals(10, txnLine.split("\t").size)
      val bookLine = export.text.lines().first { it.startsWith("BOOK\t") }
      // BOOK 行含类型在内共 14 段（13 列），第 5–8 列是私密占位。
      val cells = bookLine.split("\t")
      assertEquals(14, cells.size)
      // [0]=BOOK, [1..4]=id/name/icon/color, [5]=is_private 占位, [6]=pwd_hash 空,
      // [7]=pwd_salt 空, [8]=pwd_iter 占位 10000。
      assertEquals("0", cells[5])
      assertEquals("", cells[6])
      assertEquals("", cells[7])
      assertEquals("10000", cells[8])
      val doc = service.parseAndVerify(export.text)
      assertEquals(3, doc.counts.books)
      assertEquals(1, doc.counts.txns)
    }

  @Test
  fun restoresExportedBackup() =
    runBlocking {
      val now = System.currentTimeMillis()
      txnRepository.insert(
        TxnEntity(
          id = "txn_restore",
          bookId = "book_daily",
          categoryId = "cat_food",
          amountCents = 5000,
          occurredAt = now,
          dayKey = "2026-11-09",
          note = "晚饭",
          createdAt = now,
          updatedAt = now,
        )
      )
      val export = service.buildExport(now)
      val doc = service.parseAndVerify(export.text)
      val result = service.restore(doc)
      assertEquals(1, result.insertedTxns)
      assertEquals(1, txnRepository.listActive().size)
      assertEquals(5000L, txnRepository.listActive().first().amountCents)
      assertEquals(3, db.bookDao().countAll())
    }

  @Test
  fun mixedBackupSkipsPrivateBooksAndPrivateRows() =
    runBlocking {
      val now = 1762656000000L
      fun enc(text: String): String = Base64.getEncoder().encodeToString(text.toByteArray(Charsets.UTF_8))

      val normalBook =
        listOf(enc("b_normal"), enc("普通"), enc("ic_book_daily"), enc("#2A78D6"), "0", "", "", "10000", "1", "0", "0", "1", "2")
      val privateBook =
        listOf(enc("b_private"), enc("私密"), enc("ic_book_daily"), enc("#2A78D6"), "1", enc("hash"), enc("salt"), "10000", "0", "0", "0", "1", "2")
      val member =
        listOf(enc("m1"), enc("自己"), enc("自"), enc("#2A78D6"), "1", "0", "0")
      val group =
        listOf(enc("g1"), enc("餐饮"), "0", "1")
      val category =
        listOf(enc("c1"), enc("g1"), enc("餐饮"), enc("ic_cat_food"), enc("#EB6834"), enc("canyin"), "0", "0", "1")
      val normalTxn =
        listOf(enc("t_normal"), enc("b_normal"), enc("c1"), enc("m1"), "3200", now.toString(), enc("2026-11-09"), enc("午餐"), now.toString(), now.toString())
      val privateTxn =
        listOf(enc("t_private"), enc("b_private"), enc("c1"), enc("m1"), "9900", now.toString(), enc("2026-11-09"), enc("私密"), now.toString(), now.toString())
      val normalBudget =
        listOf(enc("budget_1"), enc("b_normal"), enc("2026-11"), "300000", now.toString())
      val privateBudget =
        listOf(enc("budget_2"), enc("b_private"), enc("2026-11"), "900000", now.toString())
      val privateRow =
        listOf(enc("b_private"), enc("salt"), enc("iv"), enc("tag"), enc("cipher"))

      val lines =
        listOf(
          BackupLine("BOOK", normalBook),
          BackupLine("BOOK", privateBook),
          BackupLine("MEMBER", member),
          BackupLine("GROUP", group),
          BackupLine("CATEGORY", category),
          BackupLine("TXN", normalTxn),
          BackupLine("TXN", privateTxn),
          BackupLine("BUDGET", normalBudget),
          BackupLine("BUDGET", privateBudget),
          BackupLine("PRIVATE", privateRow),
        )
      val body = BackupFormat.buildBody(lines)
      val checksum =
        MessageDigest.getInstance("SHA-256").digest(body.toByteArray(Charsets.UTF_8))
          .joinToString("") { "%02x".format(it) }
      val counts = BackupCounts(books = 2, categories = 1, txns = 2, budgets = 2, privateBooks = 1)
      // 故意构造 v1 旧备份：MEMBER 行与 10 列 TXN 都应被兼容读取并忽略成员。
      val text =
        BackupFormat.wrap(body, checksum, counts, now, "1.0.0")
          .replace("schemaVersion=3", "schemaVersion=1")

      val doc = service.parseAndVerify(text)
      val summary = service.summary(doc)
      assertEquals(1, summary.skippedPrivateBooks)
      assertEquals(1, summary.skippedPrivateRows)
      assertEquals(1, summary.books)
      assertEquals(1, summary.categories)

      val result = service.restore(doc)
      assertEquals(1, result.insertedTxns)
      assertEquals(1, result.skippedPrivateBooks)
      assertEquals(1, result.skippedPrivateRows)
      assertEquals(listOf("b_normal"), db.bookDao().list().map { it.id })
      assertEquals(1, txnRepository.listActive().size)
      assertEquals("t_normal", txnRepository.listActive().first().id)
      assertEquals(1, db.budgetDao().listAll().size)
    }

  @Test
  fun rejectsTamperedChecksum() {
    val body = "BOOK\taWQ="
    val text = BackupFormat.wrap(body, "deadbeef", BackupCounts(), 0, "1.0.0")
    var failed = false
    try {
      service.parseAndVerify(text)
    } catch (error: IllegalStateException) {
      failed = true
    }
    assertTrue(failed)
  }
}
