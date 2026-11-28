package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.BudgetRepository
import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.models.StatsFilter
import com.github.ppg007.moremoney.util.DateUtil
import java.time.LocalDate

data class BudgetBookView(
  val bookId: String,
  val name: String,
  val icon: String,
  val color: String,
  val cycle: BudgetCycle = BudgetCycle.MONTH,
  val budgetCents: Long = 0,
  val spentCents: Long = 0,
  val remainingCents: Long = 0,
  val percent: Float = 0f,
  val perDayCents: Long = 0,
)

data class BudgetOverview(
  /** 已设置预算的账本；默认账本（如有预算）排在最前，供预算卡默认展示。 */
  val budgeted: List<BudgetBookView> = emptyList(),
  val unset: List<BudgetBookView> = emptyList(),
)

/**
 * 预算口径：
 * - 一个账本只有一条预算配置（周期 + 金额），设置后自动按周期重复；
 * - 每个账本按自己的周期展示当前周期已用与剩余（年度看本年、季度看本季、月度看本月）；
 * - 不做跨账本合并计算；默认账本有预算时排在预算卡首位；
 * - 未设置预算的账本单独展示；
 * - 每天可用 = max(0, 剩余) / 当前周期剩余天数（含今天）。
 */
class BudgetService(
  private val bookRepository: BookRepository,
  private val budgetRepository: BudgetRepository,
  private val statsService: StatsService,
) {
  suspend fun getOverview(today: LocalDate = DateUtil.today()): BudgetOverview {
    val books = bookRepository.list().filter { !it.archived }
    val budgets = budgetRepository.listAll().associateBy { it.bookId }

    val budgeted = ArrayList<BudgetBookView>()
    val unset = ArrayList<BudgetBookView>()
    for (book in books) {
      val budget: BudgetEntity? = budgets[book.id]
      if (budget != null && budget.amountCents > 0) {
        budgeted.add(buildBookView(book, budget, today))
      } else {
        unset.add(BudgetBookView(bookId = book.id, name = book.name, icon = book.icon, color = book.color))
      }
    }

    val defaultBookId = books.firstOrNull { it.isDefault }?.id
    val defaultView = budgeted.firstOrNull { it.bookId == defaultBookId }
    val ordered =
      if (defaultView == null) {
        budgeted
      } else {
        listOf(defaultView) + budgeted.filter { it.bookId != defaultView.bookId }
      }
    return BudgetOverview(budgeted = ordered, unset = unset)
  }

  private suspend fun buildBookView(
    book: BookEntity,
    budget: BudgetEntity,
    today: LocalDate,
  ): BudgetBookView {
    val range = BudgetCycleUtil.range(budget.cycle, today)
    val spent = statsService.sum(bookFilter(book.id, range.startMs, range.endMs))
    val remaining = budget.amountCents - spent
    val perDay = remaining.coerceAtLeast(0) / BudgetCycleUtil.daysLeft(budget.cycle, today)
    return BudgetBookView(
      bookId = book.id,
      name = book.name,
      icon = book.icon,
      color = book.color,
      cycle = budget.cycle,
      budgetCents = budget.amountCents,
      spentCents = spent,
      remainingCents = remaining,
      percent = if (budget.amountCents > 0) spent.toFloat() / budget.amountCents else 0f,
      perDayCents = perDay,
    )
  }

  private fun bookFilter(bookId: String, startMs: Long, endMs: Long) =
    StatsFilter(bookIds = listOf(bookId), startMs = startMs, endMs = endMs)

  suspend fun setBudget(bookId: String, cycle: BudgetCycle, cents: Long) {
    budgetRepository.upsert(bookId, cycle, cents)
  }

  suspend fun removeBudget(bookId: String) {
    budgetRepository.remove(bookId)
  }
}
