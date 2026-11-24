package com.github.ppg007.moremoney.ui.budget

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.github.ppg007.moremoney.AppContainer
import com.github.ppg007.moremoney.service.BudgetOverview
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.ErrorUtil
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.mapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class BudgetUiState(
  val loading: Boolean = true,
  val error: String = "",
  val monthKey: String = DateUtil.monthKey(DateUtil.today()),
  val overview: BudgetOverview = BudgetOverview(),
)

/** 预算页数据：月份切换、预算合计、主预算卡与待设置预算。 */
class BudgetViewModel(private val container: AppContainer) : ViewModel() {
  private val monthKey = MutableStateFlow(DateUtil.monthKey(DateUtil.today()))

  private val trigger =
    combine(
      container.bookRepository.observeAll(),
      container.budgetRepository.observeAll(),
      container.txnRepository.observeActive(),
    ) { _, _, _ -> Unit }

  val state: StateFlow<BudgetUiState> =
    combine(trigger, monthKey) { _, month -> month }
      .mapLatest { month ->
        BudgetUiState(
          loading = false,
          monthKey = month,
          overview = container.budgetService.getOverview(month),
        )
      }
      .catch { error -> emit(BudgetUiState(loading = false, error = ErrorUtil.messageOf(error))) }
      .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BudgetUiState())

  fun changeMonth(delta: Int) {
    monthKey.value = DateUtil.addMonths(monthKey.value, delta)
  }

  fun setBudget(bookId: String, cents: Long) {
    viewModelScope.launch {
      try {
        container.budgetService.setBudget(bookId, state.value.monthKey, cents)
        container.ui.showSnack("预算已更新")
      } catch (error: Exception) {
        container.ui.showSnack("设置失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }

  fun clearBudget(bookId: String) {
    viewModelScope.launch {
      try {
        container.budgetService.removeBudget(bookId, state.value.monthKey)
        container.ui.showSnack("预算已清空")
      } catch (error: Exception) {
        container.ui.showSnack("清空失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }
}
