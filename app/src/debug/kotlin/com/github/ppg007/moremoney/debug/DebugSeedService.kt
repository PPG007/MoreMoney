package com.github.ppg007.moremoney.debug

import com.github.ppg007.moremoney.AppContainer
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.util.DateUtil

/**
 * 仅 debug 包可用的演示数据：4 个账本、30 笔本月流水、2 个预算。
 *
 * 使用固定 ID + `INSERT OR IGNORE` 语义，重复执行不会重复插入。
 */
object DebugSeedService {
  val demoBookIds = listOf("book_daily", "book_travel", "book_family", "book_repair")

  suspend fun seed(container: AppContainer) {
    val now = System.currentTimeMillis()
    val monthKey = DateUtil.monthKey(DateUtil.today())
    container.bookRepository.insertIgnore(
      BookEntity(
        id = "book_family",
        name = "家庭",
        icon = "ic_book_family",
        color = SeedColors.c5,
        isDefault = false,
        sort = 3,
        archived = false,
        createdAt = now,
        updatedAt = now,
      )
    )
    container.budgetRepository.upsert("book_daily", BudgetCycle.MONTH, 500_000)
    container.budgetRepository.upsert("book_travel", BudgetCycle.QUARTER, 600_000)

    val categories = container.categoryRepository.list().filter { !it.archived }
    if (categories.isEmpty()) {
      return
    }
    val today = DateUtil.today().dayOfMonth
    repeat(30) { index ->
      val day = (index % today.coerceAtLeast(1)) + 1
      val dayKey = "$monthKey-${day.toString().padStart(2, '0')}"
      val category = categories[index % categories.size]
      val bookId = demoBookIds[index % demoBookIds.size]
      val amount = 1_000L + (index * 437L) % 30_000L
      val occurredAt =
        DateUtil.parseDayKey(dayKey).atTime(8 + index % 12, index * 2 % 60)
          .atZone(DateUtil.zone()).toInstant().toEpochMilli()
      container.txnRepository.insert(
        TxnEntity(
          id = "demo_txn_${index + 1}",
          bookId = bookId,
          categoryId = category.id,
          amountCents = amount,
          occurredAt = occurredAt,
          dayKey = dayKey,
          note = demoNotes[index % demoNotes.size],
          createdAt = now,
          updatedAt = now,
        )
      )
    }
  }

  private val demoNotes =
    listOf("午餐", "地铁", "咖啡", "超市采购", "水电费", "电影", "打车", "书本", "水果", "房租")
}
