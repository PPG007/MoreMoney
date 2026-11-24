package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.BudgetRepository
import com.github.ppg007.moremoney.models.StatsFilter
import com.github.ppg007.moremoney.util.DateUtil

data class BudgetBookView(
  val bookId: String,
  val name: String,
  val icon: String,
  val color: String,
  val budgetCents: Long = 0,
  val spentCents: Long = 0,
  val remainingCents: Long = 0,
  val percent: Float = 0f,
)

data class BudgetOverview(
  val totalCents: Long = 0,
  val spentCents: Long = 0,
  val remainingCents: Long = 0,
  val perDayCents: Long = 0,
  val mainBook: BudgetBookView? = null,
  val others: List<BudgetBookView> = emptyList(),
  val unset: List<BudgetBookView> = emptyList(),
)

/**
 * 预算口径：
 * - 合计只包含“已设置预算（>0）且未归档”的账本；
 * - 未设置预算的账本不计入合计，单独展示；
 * - 每天可用 = max(0, 剩余) / 本月剩余天数（含今天）。
 */
class BudgetService(
  private val bookRepository: BookRepository,
  private val budgetRepository: BudgetRepository,
  private val statsService: StatsService,
) {
  suspend fun getOverview(monthKey: String): BudgetOverview {
    val books = bookRepository.list().filter { !it.archived }
    val budgets = budgetRepository.listByPeriod(monthKey)
    val range = DateUtil.rangeOfMonth(monthKey)
    val budgetMap = budgets.associateBy { it.bookId }

    val budgeted = ArrayList<BudgetBookView>()
    val unset = ArrayList<BudgetBookView>()
    for (book in books) {
      val budget: BudgetEntity? = budgetMap[book.id]
      if (budget != null && budget.amountCents > 0) {
        val filter = StatsFilter(bookIds = listOf(book.id), startMs = range.startMs, endMs = range.endMs)
        val spent = statsService.sum(filter)
        val remaining = budget.amountCents - spent
        budgeted.add(
          BudgetBookView(
            bookId = book.id,
            name = book.name,
            icon = book.icon,
            color = book.color,
            budgetCents = budget.amountCents,
            spentCents = spent,
            remainingCents = remaining,
            percent = if (budget.amountCents > 0) spent.toFloat() / budget.amountCents else 0f,
          )
        )
      } else {
        unset.add(BudgetBookView(bookId = book.id, name = book.name, icon = book.icon, color = book.color))
      }
    }

    var main: BudgetBookView? = budgeted.firstOrNull { view ->
      books.firstOrNull { it.isDefault }?.id == view.bookId
    }
    if (main == null && budgeted.isNotEmpty()) {
      main = budgeted[0]
    }
    val others = budgeted.filter { it.bookId != main?.bookId }
    val total = budgeted.sumOf { it.budgetCents }
    val spent = budgeted.sumOf { it.spentCents }
    val remaining = total - spent
    val daysLeft = PeriodResolver.daysLeftInMonth(monthKey)
    val available = remaining.coerceAtLeast(0)
    return BudgetOverview(
      totalCents = total,
      spentCents = spent,
      remainingCents = remaining,
      perDayCents = available / daysLeft,
      mainBook = main,
      others = others,
      unset = unset,
    )
  }

  suspend fun setBudget(bookId: String, period: String, cents: Long) {
    budgetRepository.upsert(bookId, period, cents)
  }

  suspend fun removeBudget(bookId: String, period: String) {
    budgetRepository.remove(bookId, period)
  }
}
