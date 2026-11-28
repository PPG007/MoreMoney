package com.github.ppg007.moremoney.ui.budget

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.github.ppg007.moremoney.AppContainer
import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.service.BudgetBookView
import com.github.ppg007.moremoney.util.ErrorUtil
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class BudgetUiState(
  val loading: Boolean = true,
  val error: String = "",
  val budgeted: List<BudgetBookView> = emptyList(),
  val unset: List<BudgetBookView> = emptyList(),
  val selectedIndex: Int = 0,
) {
  val selectedBook: BudgetBookView?
    get() = budgeted.getOrNull(selectedIndex)
}

/** 预算页数据：每账本按自身周期展示；预算卡可左右切换已设置预算的账本。 */
class BudgetViewModel(private val container: AppContainer) : ViewModel() {
  private val selectedBookId = MutableStateFlow<String?>(null)

  private val data =
    combine(
      container.bookRepository.observeAll(),
      container.budgetRepository.observeAll(),
      container.txnRepository.observeActive(),
    ) { _, _, _ -> Unit }

  val state: StateFlow<BudgetUiState> =
    combine(data, selectedBookId) { _, selectedId -> selectedId }
      .map { selectedId ->
        val overview = container.budgetService.getOverview()
        val index = overview.budgeted.indexOfFirst { it.bookId == selectedId }
        BudgetUiState(
          loading = false,
          budgeted = overview.budgeted,
          unset = overview.unset,
          selectedIndex = if (index >= 0) index else 0,
        )
      }
      .catch { error -> emit(BudgetUiState(loading = false, error = ErrorUtil.messageOf(error))) }
      .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BudgetUiState())

  fun selectPreviousBook() = cycleSelection(-1)

  fun selectNextBook() = cycleSelection(1)

  private fun cycleSelection(delta: Int) {
    val current = state.value
    if (current.budgeted.size < 2) {
      return
    }
    val size = current.budgeted.size
    val next = (current.selectedIndex + delta + size) % size
    selectedBookId.value = current.budgeted[next].bookId
  }

  fun setBudget(bookId: String, cycle: BudgetCycle, cents: Long) {
    viewModelScope.launch {
      try {
        container.budgetService.setBudget(bookId, cycle, cents)
        container.ui.showSnack("预算已更新")
      } catch (error: Exception) {
        container.ui.showSnack("设置失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }

  fun clearBudget(bookId: String) {
    viewModelScope.launch {
      try {
        container.budgetService.removeBudget(bookId)
        container.ui.showSnack("预算已清空")
      } catch (error: Exception) {
        container.ui.showSnack("清空失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }
}
