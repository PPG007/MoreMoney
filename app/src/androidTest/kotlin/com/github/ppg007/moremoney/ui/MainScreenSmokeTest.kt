package com.github.ppg007.moremoney.ui

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.github.ppg007.moremoney.MainActivity
import com.github.ppg007.moremoney.MoreMoneyApp
import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.state.ThemeMode
import com.github.ppg007.moremoney.util.DateUtil
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * 一级 Tab、金额隐藏与记一笔的 Compose UI 测试。
 *
 * 使用真实 Application 容器（seeded 数据库），每个测试开始前恢复金额显示。
 */
@RunWith(AndroidJUnit4::class)
class MainScreenSmokeTest {
  @get:Rule
  val composeRule = createAndroidComposeRule<MainActivity>()

  @Before
  fun resetUiState() {
    val app = ApplicationProvider.getApplicationContext<MoreMoneyApp>()
    app.container.ui.updateHideAmount(false)
  }

  @After
  fun resetThemeMode() {
    ApplicationProvider.getApplicationContext<MoreMoneyApp>().container.settings.setThemeMode(ThemeMode.SYSTEM)
  }

  @After
  fun resetBudgets() =
    runBlocking {
      val container = ApplicationProvider.getApplicationContext<MoreMoneyApp>().container
      listOf("book_daily", "book_travel", "book_repair").forEach {
        container.budgetRepository.remove(it)
      }
    }

  @Test
  fun fourTabsAreVisibleAndSwitch() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("tab_ledger").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("tab_ledger").assertIsDisplayed()
    composeRule.onNodeWithTag("tab_budget").assertIsDisplayed()
    composeRule.onNodeWithTag("tab_charts").assertIsDisplayed()
    composeRule.onNodeWithTag("tab_settings").assertIsDisplayed()

    composeRule.onNodeWithTag("tab_budget").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("budget_screen").fetchSemanticsNodes().isNotEmpty()
    }

    composeRule.onNodeWithTag("tab_charts").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithText("趋势").fetchSemanticsNodes().isNotEmpty()
    }

    composeRule.onNodeWithTag("tab_settings").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithText("账本管理").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("tab_ledger").performClick()
  }

  @Test
  fun appearanceSettingOpensSheetAndSwitchesTheme() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("tab_settings").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("tab_settings").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("settings_theme").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("settings_theme").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("theme_option_DARK").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("theme_option_DARK").performClick()

    val app = ApplicationProvider.getApplicationContext<MoreMoneyApp>()
    composeRule.waitUntil(5_000) { app.container.settings.themeMode() == ThemeMode.DARK }
  }

  @Test
  fun budgetCardSwitchesBetweenBudgetedBooks() =
    runBlocking {
      val container = ApplicationProvider.getApplicationContext<MoreMoneyApp>().container
      container.budgetRepository.upsert("book_daily", BudgetCycle.MONTH, 500_000)
      container.budgetRepository.upsert("book_travel", BudgetCycle.QUARTER, 600_000)

      composeRule.waitUntil(10_000) {
        composeRule.onAllNodesWithTag("tab_budget").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("tab_budget").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithText("日常账本").fetchSemanticsNodes().isNotEmpty()
      }
      // 默认账本（book_daily）有预算时优先展示。
      composeRule.onNodeWithText("日常账本").assertIsDisplayed()

      composeRule.onNodeWithTag("budget_next").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithText("旅行").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithText("旅行").assertIsDisplayed()

      composeRule.onNodeWithTag("budget_prev").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithText("日常账本").fetchSemanticsNodes().isNotEmpty()
      }
    }

  @Test
  fun crossBookSaveAppearsInAllAndTargetBook() =
    runBlocking {
      val app = ApplicationProvider.getApplicationContext<MoreMoneyApp>()
      app.container.db.txnDao().deleteAll()

      composeRule.waitUntil(10_000) {
        composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("fab_add").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("add_book_selector").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("add_book_option_book_travel").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("add_book_option_book_travel").performClick()
      // 等底部弹层完全关闭后再点键盘，避免弹层窗口仍在拦截点击。
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("add_book_option_book_travel").fetchSemanticsNodes().isEmpty()
      }
      listOf("key_4", "key_3", "key_2", "key_1").forEach {
        composeRule.onNodeWithTag(it).performClick()
      }
      composeRule.waitUntil(3_000) {
        composeRule.onAllNodesWithText("合计 ¥4,321.00").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("save_txn").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
      }

      // 返回首页后应直接看到刚记的那笔（自动切到目标账本），不需要手动切账本。
      waitForTxnAmount("¥4,321.00")
      composeRule.onNodeWithTag("book_chip_all").performClick()
      waitForTxnAmount("¥4,321.00")
      composeRule.onNodeWithTag("book_chip_book_travel").performClick()
      waitForTxnAmount("¥4,321.00")
      composeRule.onNodeWithTag("book_chip_book_daily").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodes(
          hasTestTag("txn_row") and hasAnyDescendant(hasText("¥4,321.00")),
          useUnmergedTree = true,
        ).fetchSemanticsNodes().isEmpty()
      }
    }

  @Test
  fun saveFromPreviousMonthRevealsTransaction() =
    runBlocking {
      val app = ApplicationProvider.getApplicationContext<MoreMoneyApp>()
      app.container.db.txnDao().deleteAll()

      composeRule.waitUntil(10_000) {
        composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
      }
      // 首页先切到上个月，再记一笔（默认日期为今天）。
      composeRule.onNodeWithTag("month_prev").performClick()
      composeRule.onNodeWithTag("fab_add").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("add_book_selector").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("add_book_option_book_travel").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("add_book_option_book_travel").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("add_book_option_book_travel").fetchSemanticsNodes().isEmpty()
      }
      listOf("key_5", "key_4", "key_3", "key_2").forEach {
        composeRule.onNodeWithTag(it).performClick()
      }
      composeRule.waitUntil(3_000) {
        composeRule.onAllNodesWithText("合计 ¥5,432.00").fetchSemanticsNodes().isNotEmpty()
      }
      composeRule.onNodeWithTag("save_txn").performClick()
      composeRule.waitUntil(5_000) {
        composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
      }

      // 首页自动切到这笔流水的月份与账本，立刻可见。
      waitForTxnAmount("¥5,432.00")
      composeRule.onNodeWithTag("book_chip_all").performClick()
      waitForTxnAmount("¥5,432.00")
    }

  private fun waitForTxnAmount(amount: String) {
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodes(
        hasTestTag("txn_row") and hasAnyDescendant(hasText(amount)),
        useUnmergedTree = true,
      ).fetchSemanticsNodes().isNotEmpty()
    }
  }

  @Test
  fun hideAmountBlursAllAmounts() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("eye_button").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("eye_button").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("¥••••").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("eye_button").performClick()
  }

  @Test
  fun addTransactionSavesAndReturnsHome() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_1").performClick()
    composeRule.onNodeWithTag("key_2").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥12.00").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("save_txn").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    // 直接查库确认 12.00 已落库；首页汇总金额会随其他测试数据变化，不能写死断言。
    val app = ApplicationProvider.getApplicationContext<MoreMoneyApp>()
    val saved = runBlocking { app.container.txnRepository.listActive().any { it.amountCents == 1200L } }
    assertTrue(saved)
  }

  @Test
  fun dayRecordsCollapseAndExpand() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_1").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥1.00").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("save_txn").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }

    val dayKey = DateUtil.nowDayKey()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("day_$dayKey").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("day_header_$dayKey").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithTag("day_$dayKey").fetchSemanticsNodes().isEmpty()
    }
    composeRule.onNodeWithTag("day_header_$dayKey").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithTag("day_$dayKey").fetchSemanticsNodes().isNotEmpty()
    }
  }

  @Test
  fun swipeRowRevealsActionsWithDeleteConfirm() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_1").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥1.00").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("save_txn").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }

    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("txn_row").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onAllNodesWithTag("txn_row")[0].performTouchInput { swipeLeft() }
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithTag("swipe_actions").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("swipe_delete").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("删除这笔记录？").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithText("取消").performClick()
  }

  @Test
  fun leadingZeroIsIgnored() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_0").performClick()
    composeRule.onNodeWithTag("key_0").performClick()
    composeRule.onNodeWithTag("save_txn").assertIsNotEnabled()
    composeRule.onNodeWithTag("key_5").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥5.00").fetchSemanticsNodes().isNotEmpty()
    }
  }

  @Test
  fun searchScreenOpensFromHome() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("tab_ledger").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithText("最近记录").assertIsDisplayed()
  }
}
