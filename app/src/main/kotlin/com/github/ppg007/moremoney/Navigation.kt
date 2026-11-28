package com.github.ppg007.moremoney

import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import com.github.ppg007.moremoney.ui.add.AddTxnScreen
import com.github.ppg007.moremoney.ui.books.BookManageScreen
import com.github.ppg007.moremoney.ui.categories.CategoryManageScreen
import com.github.ppg007.moremoney.ui.data.DataBackupScreen
import com.github.ppg007.moremoney.ui.main.MainScreen
import com.github.ppg007.moremoney.ui.search.SearchScreen

private const val PredictiveBackFadeMs = 220

/**
 * 根导航。一级 Tab 在 [MainScreen] 内部切换，二级页使用 Navigation 3 的
 * `@Serializable NavKey` push/pop；每个 entry 拥有独立的 ViewModelStore，
 * 返回后一级页选中态由 `rememberSaveable` 保持。
 */
@Composable
fun MainNavigation(container: AppContainer) {
  val backStack = rememberNavBackStack(Main)

  NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    // 系统预测性返回默认使用 scaleOut(0.7f) 且不淡出：页面缩到 70% 后会僵住再瞬间消失。
    // 这里改为与普通 pop 一致的交叉淡出，手势进度直接驱动透明度，结束时不会突然跳变。
    predictivePopTransitionSpec = {
      fadeIn(animationSpec = tween(PredictiveBackFadeMs)) togetherWith
        fadeOut(animationSpec = tween(PredictiveBackFadeMs))
    },
    entryDecorators =
      listOf(
        rememberSaveableStateHolderNavEntryDecorator(),
        rememberViewModelStoreNavEntryDecorator(),
      ),
    entryProvider =
      entryProvider {
        entry<Main> {
          MainScreen(
            ui = container.ui,
            onAddTxn = { bookId, dayKey -> backStack.add(AddTxn(bookId = bookId, dayKey = dayKey)) },
            onSearch = { backStack.add(Search()) },
            onEditTxn = { txnId -> backStack.add(AddTxn(txnId = txnId)) },
            onBookManage = { backStack.add(BookManage) },
            onCategoryManage = { backStack.add(CategoryManage) },
            onDataBackup = { backStack.add(DataBackup) },
          )
        }
        entry<AddTxn> { key ->
          AddTxnScreen(
            bookId = key.bookId,
            dayKey = key.dayKey,
            txnId = key.txnId,
            onBack = { backStack.removeLastOrNull() },
          )
        }
        entry<BookManage> {
          BookManageScreen(onBack = { backStack.removeLastOrNull() })
        }
        entry<CategoryManage> {
          CategoryManageScreen(onBack = { backStack.removeLastOrNull() })
        }
        entry<DataBackup> {
          DataBackupScreen(onBack = { backStack.removeLastOrNull() })
        }
        entry<Search> { key ->
          SearchScreen(
            initialBookId = key.bookId,
            ui = container.ui,
            onBack = { backStack.removeLastOrNull() },
            onEditTxn = { txnId -> backStack.add(AddTxn(txnId = txnId)) },
          )
        }
      },
  )
}
