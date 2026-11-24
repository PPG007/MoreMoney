package com.github.ppg007.moremoney.ui.common

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.github.ppg007.moremoney.AppContainer
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.service.PeriodResolver
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.ErrorUtil
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class LedgerDayGroup(
  val dayKey: String,
  val cents: Long,
  val txns: List<TxnEntity>,
)

data class HomeData(
  val books: List<BookEntity> = emptyList(),
  val categories: Map<String, CategoryEntity> = emptyMap(),
  val bookById: Map<String, BookEntity> = emptyMap(),
  val txns: List<TxnEntity> = emptyList(),
  val budgets: List<BudgetEntity> = emptyList(),
)

data class LedgerUiState(
  val loading: Boolean = true,
  val error: String = "",
  val books: List<BookEntity> = emptyList(),
  val categories: Map<String, CategoryEntity> = emptyMap(),
  val bookById: Map<String, BookEntity> = emptyMap(),
  val selectedBookId: String = "",
  val monthKey: String = DateUtil.monthKey(DateUtil.today()),
  val days: List<LedgerDayGroup> = emptyList(),
  val spentCents: Long = 0,
  val budgetCents: Long = 0,
  val hasBudget: Boolean = false,
  val perDayCents: Long = 0,
  val txnCount: Int = 0,
) {
  fun categoryOf(id: String): CategoryEntity? = categories[id]

  fun categoryName(id: String): String = categories[id]?.name ?: "未分类"

  fun categoryIcon(id: String): String = categories[id]?.icon ?: "ic_cat_other"

  fun categoryColor(id: String): String = categories[id]?.color ?: SeedColors.neutral
}

/**
 * 首页数据与操作：账本/月份切换、预算摘要、删除撤销。
 *
 * 所有数据来自 Room Flow，任何一笔新增/编辑都会自动刷新本月汇总与预算。
 */
class HomeViewModel(private val container: AppContainer) : ViewModel() {
  private val monthKey = MutableStateFlow(DateUtil.monthKey(DateUtil.today()))
  private val selectedBook = MutableStateFlow<String?>(null)

  private val dataFlow =
    combine(
      container.bookRepository.observeAll(),
      container.categoryRepository.observeAll(),
      container.txnRepository.observeActive(),
      container.budgetRepository.observeAll(),
    ) { books, categories, txns, budgets ->
      HomeData(
        books = books,
        categories = categories.associateBy { it.id },
        bookById = books.associateBy { it.id },
        txns = txns,
        budgets = budgets,
      )
    }

  private val inputsFlow = combine(monthKey, selectedBook) { month, book -> month to book }

  val state: StateFlow<LedgerUiState> =
    combine(dataFlow, inputsFlow, container.settings.state) { data, input, settings ->
      buildState(data, input.first, input.second, settings.defaultBookId)
    }
      .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), LedgerUiState())

  private fun buildState(
    data: HomeData,
    month: String,
    rawSelectedBook: String?,
    settingsBookId: String,
  ): LedgerUiState {
    val activeBooks = data.books.filter { !it.archived }
    val bookIds = activeBooks.map { it.id }
    val effectiveBook =
      when {
        rawSelectedBook == null ->
          settingsBookId.takeIf { it.isNotBlank() && it in bookIds }
            ?: activeBooks.firstOrNull { it.isDefault }?.id
            ?: ""
        rawSelectedBook in bookIds -> rawSelectedBook
        else -> ""
      }
    val selectedIds = if (effectiveBook.isEmpty()) bookIds else listOf(effectiveBook)
    val filteredTxns =
      data.txns.filter {
        it.dayKey.startsWith(month) &&
          (effectiveBook.isEmpty() || it.bookId == effectiveBook)
      }
    val days = ArrayList<LedgerDayGroup>()
    for (txn in filteredTxns) {
      val current = days.lastOrNull()
      if (current == null || current.dayKey != txn.dayKey) {
        days.add(LedgerDayGroup(txn.dayKey, txn.amountCents, listOf(txn)))
      } else {
        days[days.size - 1] = current.copy(cents = current.cents + txn.amountCents, txns = current.txns + txn)
      }
    }
    val spent = filteredTxns.sumOf { it.amountCents }
    val monthBudgets = data.budgets.filter { it.period == month && it.bookId in selectedIds && it.amountCents > 0 }
    val budgetTotal = monthBudgets.sumOf { it.amountCents }
    val hasBudget = monthBudgets.isNotEmpty()
    val perDay =
      if (!hasBudget) {
        0
      } else {
        (budgetTotal - spent).coerceAtLeast(0) / PeriodResolver.daysLeftInMonth(month)
      }

    return LedgerUiState(
      loading = false,
      books = activeBooks,
      categories = data.categories,
      bookById = data.bookById,
      selectedBookId = effectiveBook,
      monthKey = month,
      days = days,
      spentCents = spent,
      budgetCents = budgetTotal,
      hasBudget = hasBudget,
      perDayCents = perDay,
      txnCount = filteredTxns.size,
    )
  }

  fun selectBook(bookId: String) {
    selectedBook.value = bookId
  }

  fun changeMonth(delta: Int) {
    monthKey.value = DateUtil.addMonths(monthKey.value, delta)
  }

  fun deleteTxn(txn: TxnEntity) {
    viewModelScope.launch {
      try {
        container.deleteService.deleteTxn(txn.id)
        container.ui.showSnack("已删除 1 笔", "撤销", 5000) {
          viewModelScope.launch {
            try {
              container.deleteService.undoDelete(txn.id)
            } catch (error: Exception) {
              container.ui.showSnack("撤销失败：${ErrorUtil.messageOf(error)}")
            }
          }
        }
      } catch (error: Exception) {
        container.ui.showSnack("删除失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }
}
