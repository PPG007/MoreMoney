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
import com.github.ppg007.moremoney.data.repository.TxnRepository
import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.util.DateUtil
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate

/** 预算周期口径：各账本按自身周期统计，顶部合计按月折算。 */
@RunWith(AndroidJUnit4::class)
class BudgetServiceTest {
  private lateinit var db: MoreMoneyDatabase
  private lateinit var budgetRepository: BudgetRepository
  private lateinit var txnRepository: TxnRepository
  private lateinit var service: BudgetService

  @Before
  fun setUp() {
    val context: Context = ApplicationProvider.getApplicationContext()
    db =
      Room.inMemoryDatabaseBuilder(context, MoreMoneyDatabase::class.java)
        .addCallback(MoreMoneyDatabase.CALLBACK)
        .allowMainThreadQueries()
        .build()
    runBlocking { SeedData.ensureSeeded(db) }
    budgetRepository = BudgetRepository(db)
    txnRepository = TxnRepository(db)
    service = BudgetService(BookRepository(db), budgetRepository, StatsService(db))
  }

  @After
  fun tearDown() {
    db.close()
  }

  @Test
  fun overviewUsesEachBooksOwnCycle() =
    runBlocking {
      insertTxn("t_year_start", "book_daily", "2026-01-10", 1_000)
      insertTxn("t_quarter_start", "book_daily", "2026-10-05", 2_000)
      insertTxn("t_month", "book_daily", "2026-11-10", 3_000)
      insertTxn("t_travel", "book_travel", "2026-11-12", 5_000)
      insertTxn("t_last_year", "book_daily", "2025-12-31", 9_000)
      insertTxn("t_next_year", "book_daily", "2027-01-01", 7_000)

      budgetRepository.upsert("book_daily", BudgetCycle.YEAR, 120_000)
      budgetRepository.upsert("book_travel", BudgetCycle.QUARTER, 30_000)
      budgetRepository.upsert("book_repair", BudgetCycle.MONTH, 10_000)

      val overview = service.getOverview(LocalDate.of(2026, 11, 15))

      // 默认账本（book_daily）有预算时排在第一位，供预算卡默认展示。
      assertEquals(3, overview.budgeted.size)
      assertEquals("book_daily", overview.budgeted[0].bookId)
      assertEquals(listOf("book_daily", "book_travel", "book_repair"), overview.budgeted.map { it.bookId })
      assertTrue(overview.unset.isEmpty())

      // 年度预算：只统计 2026 年（含 1 月、10 月、11 月），排除 2025/2027。
      val daily = overview.budgeted.first { it.bookId == "book_daily" }
      assertEquals(BudgetCycle.YEAR, daily.cycle)
      assertEquals(120_000L, daily.budgetCents)
      assertEquals(6_000L, daily.spentCents)
      assertEquals(114_000L, daily.remainingCents)
      assertEquals(2_425L, daily.perDayCents)

      // 季度预算：当前季度为 2026 Q4，只统计 10–12 月。
      val travel = overview.budgeted.first { it.bookId == "book_travel" }
      assertEquals(BudgetCycle.QUARTER, travel.cycle)
      assertEquals(5_000L, travel.spentCents)

      // 月度预算：当前月为 2026-11。
      val repair = overview.budgeted.first { it.bookId == "book_repair" }
      assertEquals(BudgetCycle.MONTH, repair.cycle)
      assertEquals(0L, repair.spentCents)
    }

  @Test
  fun fallsBackToFirstBudgetedWhenDefaultBookHasNoBudget() =
    runBlocking {
      budgetRepository.upsert("book_travel", BudgetCycle.QUARTER, 30_000)
      budgetRepository.upsert("book_repair", BudgetCycle.MONTH, 10_000)

      val overview = service.getOverview(LocalDate.of(2026, 11, 15))

      assertEquals(listOf("book_travel", "book_repair"), overview.budgeted.map { it.bookId })
      assertEquals(listOf("book_daily"), overview.unset.map { it.bookId })
    }

  private suspend fun insertTxn(id: String, bookId: String, dayKey: String, amountCents: Long) {
    val occurredAt =
      DateUtil.parseDayKey(dayKey).atTime(12, 0).atZone(DateUtil.zone()).toInstant().toEpochMilli()
    txnRepository.insert(
      TxnEntity(
        id = id,
        bookId = bookId,
        categoryId = "cat_food",
        amountCents = amountCents,
        occurredAt = occurredAt,
        dayKey = dayKey,
        note = "",
        createdAt = occurredAt,
        updatedAt = occurredAt,
      )
    )
  }
}
